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
#include <ctime>
#include <cmath>
#include "config.h"
#include "core.h"
#define VERSION 0.1

using namespace std;
using namespace aiml;

// Reduced version of the matching algorithm found on graphmaster.cpp, look there for a thorough explanation of the code
// This version doesn't have to handle with different node types. The pattern is just a list, not a tree, so it is much easier
bool cGraphMaster::isMatch(InputIterator input, InputIterator pattern, unsigned long rec) {
  string input_head(*input);
  string patt_head(*pattern);
  input++; pattern++;

  if (patt_head == "_" && isMatchWildcard(input, pattern, rec)) return true;
  
  if (patt_head == input_head) {
    if (input.isDone()) { if (pattern.isDone()) return true; else return false; }
    else {
      if (pattern.isDone()) return false;
      else {
        if (isMatch(input, pattern, rec+1)) return true;
        else return false;
      }
    }
  }

  if (patt_head == "*" && isMatchWildcard(input, pattern, rec)) return true;
  
  return false;
}

bool cGraphMaster::isMatchWildcard(const InputIterator& input, const InputIterator& pattern, const unsigned long& rec) {
  if (input.isDone()) { if (pattern.isDone()) return true; else return false; }
  else {
    if (pattern.isDone()) return true;
    else {
      InputIterator input_copy(input);
      do { if (isMatch(input_copy, pattern, rec+1)) return true; input_copy++; } while(!input_copy.isDone());
      return false;
    }
  }
  return false;
}

/**
  N O T E: the to_lowercase() call is necessary because I do to_uppercase() with user input. I'll consider doing case-insensitive
  pattern matching
  Pc: i must be in bounds!!! [0,size())
**/
string getStrListIdx(unsigned int idx, const list<string>& str_list) {
  list<string>::const_iterator it = str_list.begin();
  for (unsigned int i = 0; i < idx; ++it) ++i;
  string lowercased(*it);
  to_lowercase(lowercased);
  return lowercased;
}

bool cGraphMaster::readTemplate(cReadBuffer& templ, const StarsHolder& sh, cUser& user, string& templ_str, std::list<cMatchLog>* log, unsigned long rec) {
  _DBG_CODE(msg_dbg() << "[" << rec << "]" << endl);

  while (!templ.at_end()) {
    _DBG_CODE(msg_dbg() << "[" << rec << "] loop" << endl);
    
    size_t len, int_type;
    size_t chars_read, chars_read_tag = 0;

    if (!(chars_read = templ.readNumber(len))) return false;
    chars_read_tag += chars_read;
    if (!(chars_read = templ.readNumber(int_type))) return false;
    chars_read_tag += chars_read;
    _DBG_CODE(msg_dbg() << "[" << rec << "] len: " << len << " type: " << int_type << endl);

    switch(int_type) {
      case TEMPL_CHARACTERS:
        // character data doesn't use the 'len' field, it has its own inside the string
        if (!(chars_read = templ.readString(templ_str, true))) return false;
        _DBG_CODE(msg_dbg() << "chardata text len: [" << chars_read - 4 << "] at " << (templ.tell() - chars_read) << endl);
      break;
      case TEMPL_CONDITION:
      {
        size_t cond_type;
        if (!(chars_read = templ.readNumber(cond_type))) return false;
        chars_read_tag += chars_read;

        switch(cond_type) {
          case TEMPL_CONDITION_BLOCK:
          {
            string name, value;
            if (!(chars_read = templ.readString(name))) return false;
            chars_read_tag += chars_read;
            if (!(chars_read = templ.readString(value))) return false;
            chars_read_tag += chars_read;

            bool matches = (value.empty() && user.getVar(name).empty());
            if (!matches && !value.empty()) {
              list<string> cond_list, value_list;
              tokenizeToList(user.getVar(name), cond_list, true, ".");
              tokenizeToList(value, value_list, true, "*");
              matches = isMatch(cond_list, value_list, 0);
            }
            if (matches) {
              string inner;
              size_t old_size = templ.limitSize(len - chars_read_tag);
              if (!readTemplate(templ, sh, user, inner, log, rec+1)) return false;
              templ.restoreSize(old_size);
              templ_str += inner;
            }
            else templ.seek(len - chars_read_tag, templ.tell());
          }
          break;
          case TEMPL_CONDITION_SINGLE:
          case TEMPL_CONDITION_MULTI:
          {
            string name, value;
            if (cond_type == TEMPL_CONDITION_SINGLE) {
              if (!(chars_read = templ.readString(name))) return false;
              chars_read_tag += chars_read;
            }

            size_t old_size = templ.limitSize(len - chars_read_tag);
            while(!templ.at_end()) {
              size_t chars_read_li = 0;
              
              // get header
              size_t li_len, li_type, li_subtype;
              if (!(chars_read = templ.readNumber(li_len))) return false;
              chars_read_li += chars_read;
              if (!(chars_read = templ.readNumber(li_type))) return false;
              chars_read_li += chars_read;

              _DBG_CODE(msg_dbg() << "li len: " << li_len << " type: " << li_type << endl);

              // skip any character data found between tags
              if (li_type != TEMPL_LI) return false;
              
              if (!(chars_read = templ.readNumber(li_subtype))) return false;
              chars_read_li += chars_read;

              bool matches = true;
              
              if ((cond_type == TEMPL_CONDITION_SINGLE && li_subtype == TEMPL_LI_VALUE) ||
                  (cond_type == TEMPL_CONDITION_MULTI && li_subtype == TEMPL_LI_NAME_VALUE))
              {
                
                if (cond_type == TEMPL_CONDITION_MULTI) {
                  if (!(chars_read = templ.readString(name))) return false;
                  chars_read_li += chars_read;
                }
                if (!(chars_read = templ.readString(value))) return false;
                chars_read_li += chars_read;

                matches = (value.empty() && user.getVar(name).empty());
                if (!matches && !value.empty()) {
                  list<string> cond_list, value_list;
                  tokenizeToList(user.getVar(name), cond_list, true, ".");
                  tokenizeToList(value, value_list, true, "*");
                  matches = isMatch(cond_list, value_list, 0);
                  _DBG_CODE(msg_dbg() << "matches [" << name << "] with [" << value << "]?: " << matches << endl);
                }
              }
              else if (li_subtype != TEMPL_LI_DEFAULT) return false;

              if (matches) {
                _DBG_CODE(msg_dbg() << "matched!" << endl);
                string inner;

                size_t old_size_li = templ.limitSize(li_len - chars_read_li);
                if (!readTemplate(templ, sh, user, inner, log, rec+1)) return false;
                templ.restoreSize(old_size_li);
                templ_str += inner;
                templ.to_end();
                break;
              }
              else templ.seek(li_len - chars_read_li, templ.tell());
            }
            templ.restoreSize(old_size);
          }
          break;
          default:
            _DBG_MARK();
            return false;
          break;
        }
      }
      break;

      case TEMPL_STAR:
      case TEMPL_TOPICSTAR:
      case TEMPL_THATSTAR:
      {
        size_t index1;
        if (!(chars_read = templ.readNumber(index1))) return false;
 
        const list<string>* curr_star = NULL;
        switch(int_type) {
          case TEMPL_STAR:      curr_star = &sh.patt;   break;
          case TEMPL_TOPICSTAR: curr_star = &sh.topic;  break;
          case TEMPL_THATSTAR:  curr_star = &sh.that;   break;
          default:
            return false;
          break;
        }
        
        if (index1 >= 1 && (index1 - 1) < curr_star->size()) templ_str += getStrListIdx(index1 - 1, *curr_star);
      }
      break;
      
      case TEMPL_THAT:
      case TEMPL_INPUT:
        {
          size_t index1, index2;
        if (!(chars_read = templ.readNumber(index1))) return false;
        if (!(chars_read = templ.readNumber(index2))) return false;

        if (int_type == TEMPL_THAT) templ_str += user.getThat(false, index1, index2);
        else templ_str += user.getInput(index1, index2);
      }
      break;

      case TEMPL_RANDOM:
      {
        vector<size_t> li_positions;

        size_t old_pos = templ.tell();
        size_t old_size = templ.limitSize(len - chars_read_tag);
        _DBG_CODE(msg_dbg() << "[" << rec << "] random" << endl);
        while(!templ.at_end()) {
          _DBG_CODE(msg_dbg() << "[" << rec << "] li " << endl);
          size_t chars_read_li = 0, chars_read;
          size_t li_len, li_type;
          li_positions.push_back(templ.tell());
          
          if (!(chars_read = templ.readNumber(li_len))) return false;
          chars_read_li += chars_read;
          if (!(chars_read = templ.readNumber(li_type))) return false;
          chars_read_li += chars_read;

          _DBG_CODE(msg_dbg() << "li of len " << li_len << " about to seek to " << li_len - chars_read_li + templ.tell() << endl);

          templ.seek(li_len - chars_read_li, templ.tell());
        }
        templ.restoreSize(old_size);

        if (li_positions.empty()) return false;
        double dsize = li_positions.size();
        size_t rand_elem = static_cast<size_t>(floor(dsize * rand() / RAND_MAX));
        templ.seek(li_positions[rand_elem]);

        size_t chars_read_li = 0;
        size_t li_len, li_type, li_subtype;
        if (!(chars_read = templ.readNumber(li_len))) return false;
        chars_read_li += chars_read;
        if (!(chars_read = templ.readNumber(li_type))) return false;
        chars_read_li += chars_read;
        if (!(chars_read = templ.readNumber(li_subtype))) return false;
        chars_read_li += chars_read;

        if (li_subtype != TEMPL_LI_DEFAULT) return false;

        // interpret the random one
        string li_content;
        old_size = templ.limitSize(li_len - chars_read_li);
        if (!readTemplate(templ, sh, user, li_content, log, rec+1)) return false;
        templ.restoreSize(old_size);
        
        templ_str += li_content;
        templ.seek(len - chars_read_tag, old_pos);
      }
      break;
      
      case TEMPL_GOSSIP:
      case TEMPL_THINK:
      {
        string inner;
        size_t old_size = templ.limitSize(len - chars_read_tag);
        if (!readTemplate(templ, sh, user, inner, log, rec+1)) return false;
        templ.restoreSize(old_size);

        if (int_type == TEMPL_GOSSIP) toGossip(inner);
      }
      break;
      case TEMPL_LEARN:
      {
        /**
         * N-O-T-E: the contents of <learn> are not template elements, but this could would interpret any template elements inside.
         * For my own sanity, I have to assume that the file is valid aiml.
         * Anyway, it doesn't makes sense to put the uri as content isntead of inside an attribute.
         **/
        string uri;
        size_t old_size = templ.limitSize(len - chars_read_tag);
        if (!readTemplate(templ, sh, user, uri, log, rec+1)) return false;
        templ.restoreSize(old_size);
        aiml_core.learn_file(uri, true);
      }
      break;
      
      case TEMPL_SRAI:
      {
        string inner;

        size_t old_size = templ.limitSize(len - chars_read_tag);
        if (!readTemplate(templ, sh, user, inner, log, rec+1)) return false;
        templ.restoreSize(old_size);

        vector<string> sentences;
        normalize(inner, sentences);
        string single_response;

        for (vector<string>::const_iterator it = sentences.begin(); it != sentences.end(); ++it) {
          if (getAnswer(*it, user, single_response, log)) templ_str += single_response + " ";
          else break;
        }
      }
      break;

      // scripted languages
      case TEMPL_SYSTEM:
      case TEMPL_JAVASCRIPT:
      {
        string chardata;
        size_t old_size = templ.limitSize(len - chars_read_tag);
        if (!readTemplate(templ, sh, user, chardata, log, rec+1)) return false;
        templ.restoreSize(old_size);

        string ret;
        bool call_ret = (int_type == TEMPL_SYSTEM ? aiml_core.doSystemCall(chardata, ret) : aiml_core.doJavaScriptCall(chardata, ret));
        if (!call_ret) return false;
        templ_str += ret;
      }
      break;

      case TEMPL_DATE:
      {
        time_t curr_time;
        time(&curr_time);

        string format, time_str;
        templ.readString(format);

        if (aiml_core.cfg_options.allow_dateformat && !format.empty()) {
          string formatted_time;
          char formatted_time_buf[512];
          size_t chars_written = strftime(formatted_time_buf, 512, format.c_str(), localtime(&curr_time));
          if (chars_written < 512) formatted_time.assign(formatted_time_buf, chars_written);
          templ_str += formatted_time;
        }
        else 
          templ_str += std_util::strip(ctime(&curr_time), '\n', std_util::RIGHT);
      }
      break;
      case TEMPL_ID:
        templ_str += user.name;
      break;
      case TEMPL_SIZE:
      {
        ostringstream osstr;
        osstr << gm_size;
        templ_str += osstr.str();
      }
      break;
      case TEMPL_VERSION:
        templ_str += string("libaiml ", VERSION);
      break;
      
      case TEMPL_PERSON:
      case TEMPL_PERSON2:
      case TEMPL_GENDER:
      case TEMPL_LOWERCASE:
      case TEMPL_UPPERCASE:
      case TEMPL_FORMAL:
      case TEMPL_SENTENCE:
      {
        string value;

        size_t old_size = templ.limitSize(len - chars_read_tag);
        if (!readTemplate(templ, sh, user, value, log, rec+1)) return false;
        templ.restoreSize(old_size);

        switch(int_type) {
          case TEMPL_PERSON:    toPerson(value);      break;
          case TEMPL_PERSON2:   toPerson2(value);     break;
          case TEMPL_GENDER:    toGender(value);      break;
          case TEMPL_LOWERCASE: to_lowercase(value);  break;
          case TEMPL_UPPERCASE: to_uppercase(value);  break;
          case TEMPL_FORMAL:    to_formal(value, aiml_core.cfg_options.sentence_limit); break;
          case TEMPL_SENTENCE:  to_sentence(value, aiml_core.cfg_options.sentence_limit); break;
        }
        templ_str += value;
      }
      break;
      
      case TEMPL_SR:
      {
        if (sh.patt.empty()) break;
        vector<string> sentences;
        normalize(getStrListIdx(0, sh.patt), sentences);
        string single_response;

        for (vector<string>::const_iterator it = sentences.begin(); it != sentences.end(); ++it) {
          if (getAnswer(*it, user, single_response, log)) templ_str += single_response + " ";
          else break;
        }
      }
      break;
      case TEMPL_PERSON_SHORT:
      case TEMPL_PERSON2_SHORT:
      case TEMPL_GENDER_SHORT:
      {
        if (sh.patt.empty()) break;
        string star(getStrListIdx(0, sh.patt));
        switch(int_type) {
          case TEMPL_PERSON_SHORT:  toPerson(star);   break;
          case TEMPL_PERSON2_SHORT: toPerson2(star);  break;
          case TEMPL_GENDER_SHORT:  toGender(star);   break;
        }
        templ_str += star;
      }
      break;
      
      case TEMPL_SET:
      {
        string name, value;
        if (!(chars_read = templ.readString(name))) return false;
        chars_read_tag += chars_read;
        
        size_t old_size = templ.limitSize(len - chars_read_tag);
        if (!readTemplate(templ, sh, user, value, log, rec+1)) return false;
        templ.restoreSize(old_size);
        
        templ_str += value;
        user.setVar(name, value);
      }
      break;
      case TEMPL_GET:
      case TEMPL_BOT:
      {
        string name;
        if (!(chars_read = templ.readString(name))) return false;
        chars_read_tag += chars_read;

        templ_str += (int_type == TEMPL_GET ? user.getVar(name) : user.getBotVar(name));
      }
      break;
      case TEMPL_UNKNOWN:
      break;
      default:
        set_error(AIMLERR_TEMLP_UNKNOWN_TAG);
        return false;
      break;
    }
  }

  return true;
}
