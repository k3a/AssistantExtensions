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

#include <list>
#include <string>
#include <std_utils/cconfig.h>
#include <std_utils/std_util.h>
#include "core.h"

using namespace std;
using namespace std_util;
using namespace aiml;

cUser::cUser(void) : botvars_map(NULL), graphmaster(NULL), last_error(NULL) { }
cUser::cUser(const string& _name, AIMLError* _last_error, const StringMAP* _botvars_map, const cGraphMaster* gm) :
    name(_name), botvars_map(_botvars_map), graphmaster(gm), last_error(_last_error) { }

/**
 Precondition = which is a valid [1,MAX_THAT_SIZE] number; sentence is a [1,n)
  (being 'n' a valid number depending on the number of sentences in that response)
 **/
const string& cUser::getThat(bool for_matching, unsigned int which, unsigned int sentence) const {
  if (which == 0 || sentence == 0) { set_error(AIMLERR_NEG_THAT_INDEX); return emptyString; }
  if (which > LIBAIML_MAX_THAT_SIZE || sentence > that_array[which-1].size()) return (for_matching ? dotString : emptyString);
    
  unsigned int sentence_realnum = that_array[which-1].size() - sentence;
  return (that_array[which-1])[sentence_realnum];
}

void cUser::getMatchList(NodeType type, list<string>& out) const {
  string curr_list;
  switch(type) {
    case NODE_THAT:   curr_list = getThat();  break;
    case NODE_TOPIC:  curr_list = getTopic(); break;
    case NODE_PATT:                           break;
  }
  if (curr_list == ".") out.push_back(".");
  else {
    graphmaster->normalize_sentence(curr_list);
    tokenizeToList(curr_list, out, true);
  }
}

/**
  N O T E: Altought most of the AIML sets (including AAA) use the return-name-when-set implicitly for certaing vars,
  I'm not supporting this for now because it isn't part of the spec
 **/
const string& cUser::setVar(const string& key, const string& value) {
  string final_value(strip(value));
  StringMAP::iterator it = vars_map.find(key);
  
  if (final_value.empty()) {
    if (it != vars_map.end()) vars_map.erase(it);
  }
  else vars_map[key] = strip(value);
  
  return value;
}

const string& cUser::getVar(const string& key) const {
  StringMAP::const_iterator it = vars_map.find(key);
  if (it != vars_map.end()) { _DBG_CODE(msg_dbg() << "get [" << (*it).first << "]" << endl); return (*it).second; }
  else return emptyString;
}

const StringMAP& cUser::getAllVars(void) const {
  return vars_map;
}

const string& cUser::getBotVar(const string& key) const {
  StringMAP::const_iterator it = botvars_map->find(key);
  if (it != botvars_map->end()) return (*it).second;
  return emptyString;
}


const string& cUser::getInput(unsigned int which, unsigned int sentence) const {
  if (which == 0 || sentence == 0) { set_error(AIMLERR_NEG_INPUT_INDEX); return emptyString; }
  if (which > LIBAIML_MAX_INPUTS_SAVED || sentence > input_array[which-1].size()) return emptyString;

  unsigned int sentence_realnum = input_array[which-1].size() - sentence;
  return (input_array[which-1])[sentence_realnum];

}

const string& cUser::getTopic(void) const {
  StringMAP::const_iterator it = vars_map.find("topic");
  if (it != vars_map.end()) return (*it).second;
  else return emptyString;
}

void cUser::addBotThat(const vector<string>& that) {
  for (unsigned int i = LIBAIML_MAX_THAT_SIZE-1; i; --i) that_array[i] = that_array[i-1];
  that_array[0] = that;
}

void cUser::addUserInput(vector<string> input) {
  for (unsigned int i = LIBAIML_MAX_INPUTS_SAVED-1; i; --i) input_array[i] = input_array[i-1];
  for (vector<string>::iterator it = input.begin(); it != input.end(); ++it) to_lowercase(*it);
  input_array[0] = input;
}

void cUser::set_error(AIMLError errnum) const { *last_error = errnum; }

