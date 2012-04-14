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

#ifndef __LIBAIML_GLOBAL_H__
#define __LIBAIML_GLOBAL_H__

#include <ostream>
#include <string>
#include <list>
#include <vector>
#include <map>

#define INV_BAD_CAST(s) reinterpret_cast<const char*>(s)

namespace aiml {
  void tokenizeToList(const std::string& input, std::list<std::string>& out, bool cant_be_empty = false, const char* str = NULL);

  void to_uppercase(std::string& text);
  void to_lowercase(std::string& text);
  void to_formal(std::string& text, const std::string& sentence_limit);
  void to_sentence(std::string& text, const std::string& sentence_limit);
 
  void do_split(std::string input, std::vector<std::string>& out, const std::string& sentence_limit, bool do_fitting = true);
  void do_pattern_fitting(std::string& input);
  void clean_pattern(std::string& pattern);

#ifdef _DEBUG
  std::ostream& msg_dbg(bool add_prefix = true);
  #define _DBG_CODE(x) x
  #define _DBG_MARK() _DBG_CODE(msg_dbg() << "Mark (" << __FILE__ << ":" << __LINE__ << ")" << endl)
#else
  #define _DBG_CODE(x)
  #define _DBG_MARK()
#endif

  enum NodeType { NODE_PATT, NODE_THAT, NODE_TOPIC };
  NodeType nextNodeType(const NodeType& a);
  
  typedef std::map<std::string, std::string> StringMAP;
  extern const std::string emptyString;
  extern const std::string dotString;
}

#endif
