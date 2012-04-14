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

#ifndef __LIBAIML_USER_MANAGER__
#define __LIBAIML_USER_MANAGER__

#include <libxml/parser.h>

namespace aiml {
  class cUserManager {
    public:
    cUserManager(cCore& _core);
    ~cUserManager(void);
    
    bool load(const std::string& file);
    bool save(const std::string& file);
    const std::string& getRuntimeError(void);

  private:
    cCore& core;
    xmlParserCtxt* xml_parser;
    std::string runtime_error;
  };
}

#endif // __LIBAIML_USER_MANAGER__
