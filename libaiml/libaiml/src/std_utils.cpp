/***************************************************************************
 *   This file is part of "std_utils" library.                             *
 *   Copyright (C) 2005 by V01D                                            *
 *                                                                         *
 *   "std_utils" is free software; you can redistribute it and/or modify   *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   "std_utils" is distributed in the hope that it will be useful,        *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.             *
 ***************************************************************************/
#include <sstream>
#include <iostream>
#include "std_util.h"
using std::string;
using std::ostringstream;
using std::istringstream;

/**
 * strips a string from a specific leading and/or trailing character.
 * \param src the string to strip.
 * \param c the character to find and remove from src.
 * \param sides indicates which "side to strip (leading, trailing or both).
 * \returns a copy of the stripped string
 */
string std_util::strip(const string& src, char c, STRIP_SIDE sides) {
  return strip(src, string(1, c), sides);
}

/**
 * strips a string from specific leading and/or trailing characters.
 * \param src the string to strip.
 * \param chars the characters to find and remove from src.
 * \param sides indicates which "side to strip (leading, trailing or both).
 * \returns a copy of the stripped string
 */
string std_util::strip(const string& src, const string& chars, STRIP_SIDE sides) {
  size_t start = 0, end = 0, length = src.length();
  if (length == 0 || chars.empty()) return string();
  
  if (sides == LEFT || sides == BOTH) start = src.find_first_not_of(chars);
  if (sides == RIGHT || sides == BOTH) end = src.find_last_not_of(chars);

  if (sides == LEFT) return (start == string::npos ? string() : src.substr(start));
  else if (sides == RIGHT) return (end == string::npos ? string() : src.substr(0, end+1));
  else {
    if (start == string::npos || end == string::npos) return string();
    else return src.substr(start, end - start + 1);
  }
}

/**
 * tokenizes a given string and returns the requested token(s) (reentrant version).
 * \param src is the string to tokenize.
 * \param dest will contain the token(s) found if the search was succesfull.
 * \param toknum is the token number to return (counting from 1).
 * \param all_tokens indicates whether gettok() should return the toknum'th token (false), or all
 * tokens including and following the toknum'th token (true).
 * \param sep indicates the character to interpret as token delimiter.
 * \returns true if the tokens requested were found.
 */
bool std_util::gettok(const std::string& src, std::string& dest, size_t toknum, bool all_tokens, char sep) {
  if (toknum < 1) return false;
  size_t length = src.size();
  if (length == 0) return false;

  size_t start = 0, tok_len = 0;
  size_t tok_count = 0;
  bool inToken = false;
  // string out;

  for (size_t i = 0; i < length; i++) {
    if (inToken) {
      if (src[i] == sep || i == (length-1)) {
        inToken = false;
        if (tok_count == toknum || (all_tokens && tok_count >= toknum)) {
          if (src[i] != sep && i == (length-1)) tok_len++;
          if (all_tokens) {
            if (tok_len != 0 && (tok_count-toknum) != 0) dest += sep;
            dest += src.substr(start, tok_len);
          }
          else { dest = src.substr(start,tok_len); return true; }
        }
      }
      if (src[i] != sep) tok_len++;
    }
    else if (src[i] != sep) { start = i; inToken = true; tok_len = 1; tok_count++; }
  }

  // If I get here it means that the last token wasn't "closed"
  if (!all_tokens && toknum == tok_count) { dest = src.substr(start, tok_len); return true; }
  else if (all_tokens && tok_count >= toknum) {
    // Getting here with all_tokens == true, doesn't really mean that I left the last tok "open", this checks it
    if (inToken) { if (tok_count != toknum) dest += sep; dest += src.substr(start, tok_len); }
    return true;
  }
  return false;
}

/**
 * tokenizes a given string and returns the requested token(s).
 * \param src is the string to tokenize.
 * \param toknum is the token number to return (counting from 1).
 * \param all_tokens indicates whether gettok() should return the toknum'th token (false), or all
 * tokens including and following the toknum'th token (true).
 * \param sep indicates the character to interpret as token delimiter.
 * \returns a copy of the token(s) found (if any), or an empty string otherwise.
 */
string std_util::gettok(const string& src, size_t toknum, bool all_tokens, char sep) {
  string out;
  if (!gettok(src, out, toknum, all_tokens, sep)) return string();
  else return out;
}

