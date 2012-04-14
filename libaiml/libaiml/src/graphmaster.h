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

#ifndef __LIBAIML_GRAPHMASTER_H__
#define __LIBAIML_GRAPHMASTER_H__

#include <string>
#include <list>
#include <set>
#include <fstream>

namespace aiml {
  class cCore;
  
  class AIMLentry {
    public:
      std::list<std::string>& getList(NodeType type);
    
      std::list<std::string> topic, that, patt;
      cWriteBuffer templ;
  };
  
  class Node;
  typedef std::vector<Node> NodeVec;
  typedef std::list<AIMLentry> EntryList;
  
  class Node {
    public:
      std::string key;
      cWriteBuffer templ;
      NodeVec same_childs, diff_childs;
      NodeType type;
  
      bool operator< (const Node& other) const;
  };
  
  typedef std::list<std::string>::iterator StarIt;
    
  class StarsHolder {
    public:
      StarIt AddStar(const std::string& star, NodeType word_type);
      void DelStar(StarIt it, NodeType word_type);
          
      std::list<std::string> patt, that, topic;
  };
  
  class InputIterator {
    public:
      InputIterator(const std::list<std::string>& input) : current(input.begin()), end(input.end()) { }
      bool isDone(void) const { return (current == end); }
      const std::string& operator*(void) const { return *current; }
      void operator++(int) { ++current; }
  
    private:
      std::list<std::string>::const_iterator current;
      std::list<std::string>::const_iterator end;
  };
  
  class cUser;
  
  class cGraphMaster {
    public:
      cGraphMaster(std::ofstream& gossip_stream, aiml::AIMLError& error_num, cCore& aiml_core);
  
      bool getAnswer(const std::string& input, cUser& user, std::string& output, std::list<aiml::cMatchLog>* log = NULL);
      
      void addEntry(AIMLentry& entry, bool insert_ordered);
      void sort_all(void);
  
      enum SubsType { SubsTypePerson, SubsTypePerson2, SubsTypeGender, SubsTypeGeneral };
      void addSubstitution(const std::string& from, const std::string& to, SubsType type, bool is_a_regex);
      void normalize(std::string input, std::vector<std::string>& out);
      void normalize_sentence(std::string& sentence) const;
  
      // to be used be CAIMLParser
      unsigned long& getSize(void);
      NodeVec& getRoot(void);
  
    private:
      cCore& aiml_core;
      std::ofstream& gossip_stream;
      unsigned long gm_size;
      NodeVec root;
  
      void toPerson(std::string& input);
      void toPerson2(std::string& input);
      void toGender(std::string& input);
      void toGossip(const std::string& input);
  
      void internal_sort(NodeVec& tree);
      void addNode(AIMLentry& entry, NodeType curr_type, NodeVec& tree, unsigned long rec, bool insert_ordered = false);
  
      void set_error(aiml::AIMLError num);
      aiml::AIMLError& last_error;
  
      enum WILDCARD_TYPE { WILDCARD_AST, WILDCARD_LOWER };
  
      struct MatcherStruct {
        MatcherStruct(cUser& _user, std::list<aiml::cMatchLog>* _log) : user(_user), log(_log) { }
    
        cWriteBuffer templ;
        cUser& user;
        StarsHolder sh;
        std::list<aiml::cMatchLog>* log;
  
        std::list<std::string> pattern_log, that_log, topic_log;
        void logMatch(const std::string& match, NodeType type) {
          aiml::cMatchLog& match_log = log->back();
          _DBG_CODE(msg_dbg() << "LOG match: [" << match << "]" << std::endl);
          switch(type) {
            case NODE_PATT:   match_log.pattern.push_front(match);  break;
            case NODE_THAT:   match_log.that.push_front(match);     break;
            case NODE_TOPIC:  match_log.topic.push_front(match);    break;
          }
        }
      };
    
      bool getMatch(InputIterator input, NodeType curr_type, const NodeVec& tree, MatcherStruct& ms, unsigned long rec);
      bool getMatchWildcard(const InputIterator& input, const NodeType& curr_type, const Node& tree_frontback, MatcherStruct& ms, const unsigned long& rec, const std::string& input_front);
      bool readTemplate(cReadBuffer& templ, const StarsHolder& sh, cUser& user, std::string& templ_str, std::list<aiml::cMatchLog>* log, unsigned long rec = 0);
  
      bool isMatch(InputIterator input, InputIterator pattern, unsigned long rec);
      bool isMatchWildcard(const InputIterator& input, const InputIterator& pattern, const unsigned long& rec);
  
      /** Substitution stuff **/
      struct SubstitutionPair {
        std::string from, to;
        bool regex;
      };
  
      typedef std::list<SubstitutionPair> SubstitutionList;
      SubstitutionList general_subs, person_subs, person2_subs, gender_subs;
  
      void do_substitutions(std::string& input, const SubstitutionList& subs_vec) const;
  };
}

#endif
