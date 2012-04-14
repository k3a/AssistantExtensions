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

#include <ctype.h>
#include <std_utils/std_util.h>
#include "core.h"
using namespace std;
using namespace aiml;

const string aiml::emptyString;
const string aiml::dotString = ".";

void aiml::tokenizeToList(const string& input, std::list<std::string>& out, bool cant_be_empty, const char* str) {
  string token;
  for (size_t i = 1; std_util::gettok(input, token, i); i++) out.push_back(token);
  if (cant_be_empty && out.empty()) out.push_back(str ? str : ".");
}

void aiml::to_uppercase(string& text) {
  for (string::iterator it = text.begin(); it != text.end(); ++it) *it = toupper(*it);
}

void aiml::to_lowercase(string& text) {
  for (string::iterator it = text.begin(); it != text.end(); ++it) *it = tolower(*it);
}

void aiml::to_formal(string& text, const string& sentence_limit) {
  to_sentence(text, sentence_limit + " ");
}

void aiml::to_sentence(string& text, const string& sentence_limit) {
  bool inside_sentence = false;
  size_t pos = 0;
  while(pos != string::npos) {
    if (inside_sentence) {
      pos = text.find_first_of(sentence_limit, pos);
      if (pos != string::npos) inside_sentence = false;
    }
    else {
      pos = text.find_first_not_of(sentence_limit + " ", pos);
      if (pos != string::npos) {
        inside_sentence = true;
        if (isalpha(text[pos])) text[pos] = toupper(text[pos]);
      }
    }
  }
}

void aiml::do_split(string input, vector<string>& out, const string& sentence_limit, bool do_fitting) {
  string sentence;
  size_t pos = input.find_first_of(sentence_limit);
  bool should_end = false;
  while(!should_end) {
    // process and save the sentence
    if (pos == string::npos) { should_end = true; sentence = input; }
    else { sentence = input.substr(0, pos); }
    if (do_fitting) do_pattern_fitting(sentence);
    sentence = std_util::strip(sentence);
    if (!sentence.empty()) out.push_back(sentence);

    // any more sentences?
    if (should_end) break;

    // if there are, skip more sentence delimiters and space before looking for next one
    pos = input.find_first_not_of(sentence_limit + " ", pos);
    if (pos == string::npos) break;
    input = input.substr(pos);
    pos = input.find_first_of(sentence_limit);
  }
}

// leaves only alphanumeric characters and makes them all uppercase
void aiml::do_pattern_fitting(string& input) {
  for (string::iterator it = input.begin(); it != input.end(); ++it) {
    if (!isalnum(*it)) (*it) = ' ';
    else (*it) = toupper(*it);
  }
}

// similar to above but directed to patterns read from .aiml files, which should only contain spaces, '*', '_', and alphanumeric
// characters
void aiml::clean_pattern(string& pattern) {
  for (string::iterator it = pattern.begin(); it != pattern.end(); ++it) {
    if (!isalnum(*it) && *it != '*' && *it != '_' && *it != ' ') (*it) = ' ';
    else (*it) = toupper(*it);
  }
}

/** NodeType operations **/
NodeType aiml::nextNodeType(const NodeType& a) {
  switch(a) {
    case NODE_PATT:   return NODE_THAT;   break;
    case NODE_THAT:   return NODE_TOPIC;  break;
    case NODE_TOPIC:  return NODE_TOPIC;  break;
  }
  return NODE_TOPIC;        // never reached
}
