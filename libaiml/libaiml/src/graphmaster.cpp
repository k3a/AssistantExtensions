/***************************************************************************
 *   This file is part of "libaiml"                                        *
 *   Copyright (C) 2005 by V01D                                            *
 *                                                                         *
 *   "libaiml" is free software; you can redistribute it and/or modify     *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   "libaiml" is distributed in the hope that it will be useful,          *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with "libaiml"; if not, write to the                            *
 *   Free Software Foundation, Inc.,                                       *
 *   59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.             *
 ***************************************************************************/

#include <std_utils/std_util.h>
#include <list>
#include <stack>
#include "config.h"
#include "core.h"

#ifdef ENABLE_PCRECPP
#include <pcrecpp.h>
#endif

using namespace std;
using namespace aiml;
using namespace aiml;
using std_util::gettok;
using std_util::strip;

/**
 * Constructor
 */
cGraphMaster::cGraphMaster(ofstream& _gossip_stream, AIMLError& error_num, cCore& _aiml_core) : aiml_core(_aiml_core),
  gossip_stream(_gossip_stream), gm_size(0), last_error(error_num) { }

/**
 * Strict weak ordering of nodes
 */
bool Node::operator<(const Node& a) const {
  if (key == a.key) return false;
  else if (key == "*") return false;
  else if (key == "_") return true;
  else {
    if (a.key == "*") return true;
    else if (a.key == "_") return false;
    else return (key < a.key);    /** CHECK: this sould always take two equally-cased strings **/
  }
}

unsigned long& cGraphMaster::getSize(void) { return gm_size; }
NodeVec& cGraphMaster::getRoot(void) { return root; }

/**
 * Node & entry handling
 */
void cGraphMaster::addEntry(AIMLentry& entry, bool insert_ordered) { addNode(entry, NODE_PATT, root, 0, insert_ordered); }

void cGraphMaster::addNode(AIMLentry& entry, NodeType curr_type, NodeVec& tree, unsigned long rec, bool insert_ordered) {
  list<string>& curr_list = entry.getList(curr_type);
  string head = curr_list.front();
  curr_list.pop_front();
  bool last_tok = curr_list.empty();

  Node node;
  node.key = head;
  node.type = curr_type;

  for (NodeVec::iterator it = tree.begin(); it != tree.end(); ++it) {
    if (it->key == head) {
      if (last_tok) {
        if (curr_type == NODE_TOPIC) it->templ = entry.templ;
        else addNode(entry, nextNodeType(curr_type), it->diff_childs, rec+1);
      }
      else addNode(entry, curr_type, it->same_childs, rec+1);
      
      return;
    }
  }

  if (!last_tok) addNode(entry, curr_type, node.same_childs, rec+1);
  else {
    if (curr_type == NODE_TOPIC) { node.templ = entry.templ; gm_size++; }
    else addNode(entry, nextNodeType(curr_type), node.diff_childs, rec+1);
  }

  if (insert_ordered) tree.insert(lower_bound(tree.begin(), tree.end(), node), node);
  else tree.insert(tree.end(), node);
}

/**
 * Input transformations
 */
void cGraphMaster::addSubstitution(const std::string& from, const std::string& to, SubsType type, bool is_a_regex) {
  SubstitutionPair subs_pair = { from, to, is_a_regex };

  // this avoids doing tolower() when doing case insensitive comparison
  if (!is_a_regex) to_lowercase(subs_pair.from);
  
#ifdef ENABLE_PCRECPP
  if (is_a_regex) {
    pcrecpp::RE exp(from);
    if (!exp.error().empty()) throw string("regular expression error: ") + exp.error();
  }
#endif

  switch(type) {
    case SubsTypePerson:  person_subs.push_back(subs_pair);   break;
    case SubsTypePerson2: person2_subs.push_back(subs_pair);  break;
    case SubsTypeGender:  gender_subs.push_back(subs_pair);   break;
    case SubsTypeGeneral: general_subs.push_back(subs_pair);  break;
  }
}

void cGraphMaster::toGossip(const string& input) { gossip_stream << input << endl; }
void cGraphMaster::toPerson(string& input) { do_substitutions(input, person_subs); }
void cGraphMaster::toPerson2(string& input) { do_substitutions(input, person2_subs); }
void cGraphMaster::toGender(string& input) { do_substitutions(input, gender_subs); }

void cGraphMaster::normalize(string input, vector<string>& out) {
  do_substitutions(input, general_subs);
  do_split(input, out, aiml_core.cfg_options.sentence_limit);
}

void cGraphMaster::normalize_sentence(string& sentence) const {
  do_substitutions(sentence, general_subs);
  do_pattern_fitting(sentence);
}

void cGraphMaster::do_substitutions(string& input, const SubstitutionList& subs_vec) const {
  for (SubstitutionList::const_iterator it = subs_vec.begin(); it != subs_vec.end(); ++it) {
    // from is already lowercase
    const string& from = it->from;
    const string& to = it->to;
    
    if (!it->regex) {
      for (size_t i = 0; i < input.length(); i++) {
        size_t j;
        for (j = 0; (i+j) < input.length() && j < from.length(); j++) {
          if (tolower(input[i+j]) != from[j]) break;
        }
        if (j == from.length()) {
          // even if there's a match I need that chars around the matching part be [^A-Za-z0-9']
          if (((i > 0 && !isalnum(input[i-1]) && input[i-1] != '\'') || i == 0) &&
              (((i + from.length()) < input.length() && !isalnum(input[i + from.length()]) && input[i + from.length()] != '\'') ||
                i + from.length() >= input.length()))
          {
            input.replace(i, from.length(), to);
            if (!to.empty()) i += (to.length() - 1);
          }
        }
      }
    }
    else {
#ifdef ENABLE_PCRECPP
      pcrecpp::RE(from).GlobalReplace(to, &input);
#endif
    }
  }
}

/**
 * Public interface
 */

bool cGraphMaster::getAnswer(const string& input, cUser& user, string& output, std::list<cMatchLog>* log) {
  MatcherStruct ms(user, log);
  list<string> input_list;
  
  tokenizeToList(input, input_list);
  bool is_empty = input_list.empty();

  if (is_empty) { set_error(AIMLERR_EMPTY_INPUT); return false; }
  else if (root.empty()) { set_error(AIMLERR_EMPTY_GM); return false; }
  else {
    if (log) log->resize(log->size() + 1);
    
    if (!getMatch(is_empty ? list<string>(1, ".") : input_list, NODE_PATT, root, ms, 0)) {
      set_error(AIMLERR_NO_MATCH);
      if (log) log->pop_back();
      return false;
    }
  }

  output.clear();
  ms.templ.seek(0);
  cReadBuffer read_buf(ms.templ);
  if (!readTemplate(read_buf, ms.sh, ms.user, output, log)) return false;
  return true;
}

bool cGraphMaster::getMatch(InputIterator input, NodeType curr_type, const NodeVec& tree, MatcherStruct& ms, unsigned long rec) {
  // save head of input and advance iterator
  string input_front = *input;
  input++;

  _DBG_CODE(msg_dbg() << "[" << rec << "]getMatch(" << curr_type << ") HEAD: [" << input_front << "] last input?:" << boolalpha << input.isDone() << endl);
  
  /** FIRST WILDCARD: try to match the '_' wildcard **/
  if (tree.front().key == "_") {
    _DBG_CODE(msg_dbg() << "[" << rec << "]" << "Looking in '_'" << endl);
    if (getMatchWildcard(input, curr_type, tree.front(), ms, rec, input_front)) { if (ms.log) ms.logMatch("_", curr_type); return true; }
  }
  
  /** KEYS: if wildcard didn't matched, look for specific matching keys against current input_front **/
  _DBG_CODE(msg_dbg() << "[" << rec << "]" << "KEYS" << endl);
  Node tmp_node;
  tmp_node.key = input_front;
  NodeVec::const_iterator it = lower_bound(tree.begin(), tree.end(), tmp_node);
  // if there was a match
  if (it != tree.end() && it->key == input_front) {
    // if there are more tokens on input
    if (!input.isDone()) {
      // if I have something to match with, then look for a match
      if (!it->same_childs.empty()) {
        if (getMatch(input, curr_type, it->same_childs, ms, rec+1)) { if (ms.log) ms.logMatch(it->key, curr_type); return true; }
      }
    }
    // else, this is the last token
    else {
      // get the the next type of nodes to match if necessary
      list<string> match_list;
      if (curr_type != NODE_TOPIC && !it->diff_childs.empty()) ms.user.getMatchList(NodeType(curr_type+1), match_list);

      // if in previous situation check if there's a match deeper
      if (curr_type != NODE_TOPIC && !it->diff_childs.empty() &&
          getMatch(match_list, nextNodeType(curr_type), it->diff_childs, ms, rec+1))
      {
        if (ms.log) ms.logMatch(it->key, curr_type); return true;
      }
      // if I'm in the final type of nodes, it needs to be a leaf to have a match
      else if (curr_type == NODE_TOPIC && !it->templ.empty()) {
        ms.templ = it->templ;
        if (ms.log) ms.logMatch(it->key, curr_type);
        return true;
      }
    }
  }

  /** LAST WILDCARD: if above didn't matched repeat procedure for '_' **/
  if (tree.back().key == "*") {
    _DBG_CODE(msg_dbg() << "[" << rec << "]" << "Looking in '*'" << endl);
    if (getMatchWildcard(input, curr_type, tree.back(), ms, rec, input_front)) { if (ms.log) ms.logMatch("*", curr_type); return true; }
  }
  
  return false;
}

bool cGraphMaster::getMatchWildcard(const InputIterator& input, const NodeType& curr_type, const Node& tree_frontback, MatcherStruct& ms, const unsigned long& rec, const string& input_front) {
  // add the head token to the <*star/>, will remove it if it didn't matched later
  StarIt it = ms.sh.AddStar(input_front, curr_type);

  // if this is not the last token of input
  if (!input.isDone()) {
    // if this is the last node of the path, then it is a match (save the star and then proceed to match the next node type)
    if (tree_frontback.same_childs.empty()) {
      for (InputIterator input_copy(input); !input_copy.isDone(); input_copy++) *it += string(" ") + *input_copy;
    }
    // it isn't, so try matching this token with the wildcard and match the rest in a deeper recursion,
    // after that start making a bigger match for current wildcard, until all trailing input is matched against this wildcard
    else {
      InputIterator input_copy(input);
      do {
        if (getMatch(input_copy, curr_type, tree_frontback.same_childs, ms, rec+1)) return true;
        *it += string(" ") + *input_copy; input_copy++;
      } while(!input_copy.isDone());
    }
  }

  // this is reached if the match is in this recursion level (the deepest level will set the template and return true,
  // so I don't have to do anything but pass the 'true' if getMatch() returns true)
  // This situation is because either:
  //  a) one token of input (sure match, I have to continue the matching job deeper)
  //  b) more than one token of input and:
  //    b.1) trailing wildcard (sure match, eats all available input)
  //    b.2) the wildcard couldn't be used to match just a part of the trailing input, so it matches ALL the trailing input

  // if i'm not in the final type (ie: not matching the topic) of node and there are other type of nodes I
  // should get the next type of nodes to match
  list<string> match_list;
  if (curr_type != NODE_TOPIC && !tree_frontback.diff_childs.empty())
    ms.user.getMatchList(NodeType(curr_type+1), match_list);

  // so, If I'm in the previous situation AND there's a match with the current match list I should return 'there is a match'
  if (curr_type != NODE_TOPIC && !tree_frontback.diff_childs.empty() &&
       getMatch(match_list, nextNodeType(curr_type), tree_frontback.diff_childs, ms, rec+1)) return true;

  // if not, I need to see if I'm matching the topic AND I reached a possible leaf, if so I'm all done, set the template
  else if (curr_type == NODE_TOPIC && !tree_frontback.templ.empty()) { ms.templ = tree_frontback.templ; return true; }

  // If I reach here, then there was no match anywere, so I remove the previously added token from <*star>
  ms.sh.DelStar(it, curr_type);
  return false;
}

/**
 * Sorts the whole tree
 */
void cGraphMaster::sort_all(void) {
  internal_sort(root);
}

void cGraphMaster::internal_sort(NodeVec& tree) {
  sort(tree.begin(), tree.end());
  for (NodeVec::iterator it = tree.begin(); it != tree.end(); ++it) {
    internal_sort(it->same_childs);
    internal_sort(it->diff_childs);
  }
}

/**
 * Utility functions from other types
 */
list<string>& AIMLentry::getList(NodeType type) {
  switch(type) {
    case NODE_PATT:  return patt;  break;
    case NODE_THAT:  return that;  break;
    case NODE_TOPIC: return topic; break;
  }
  return patt;      // never reached
}

list<string>::iterator StarsHolder::AddStar(const string& star, NodeType word_type) {
  list<string>::iterator it;
  switch (word_type) {
    case NODE_PATT:   patt.push_back(star);   it = patt.end();  break;
    case NODE_THAT:   that.push_back(star);   it = that.end();  break;
    case NODE_TOPIC:  topic.push_back(star);  it = topic.end(); break;
  }
  return --it;
}

void StarsHolder::DelStar(list<string>::iterator it, NodeType word_type) {
  switch (word_type) {
    case NODE_PATT:   patt.erase(it);   break;
    case NODE_THAT:   that.erase(it);   break;
    case NODE_TOPIC:  topic.erase(it);  break;
  }
}

/**
 * Utility functions -period-
 */
void cGraphMaster::set_error(AIMLError error_num) { last_error = error_num; }
