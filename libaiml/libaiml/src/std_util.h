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

#ifndef __STD_UTILS_H__
#define __STD_UTILS_H__

#include <string>
#include <sstream>

/**
 * This namespace holds everything under this project.
 * See the documentation for each of the defined classes members.
 */
namespace std_util {
  /** Indicates which "side" of the string to strip. \see strip() */
  enum STRIP_SIDE { LEFT, RIGHT, BOTH };
  
  std::string strip(const std::string& src, char c = ' ', STRIP_SIDE sides = BOTH);
  std::string strip(const std::string& src, const std::string& chars, STRIP_SIDE sides = BOTH);

  bool gettok(const std::string& src, std::string& dest, size_t toknum, bool all_tokens = false, char sep = ' ');
  std::string gettok(const std::string& src, size_t toknum, bool all_tokens = false, char sep = ' ');

  /** concatenate other types to a string. */
  template<class T> std::string& operator<<(std::string& str, const T& elem) {
    std::ostringstream out;
    out << elem;
    str += out.str();
    return str;
  }
}

/**
 * \namespace stdu
 * namespace alias for "std_util" namespace.
 * It's shorter =b.
 */
namespace stdu = std_util;

#endif
