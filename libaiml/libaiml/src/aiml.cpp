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

#include "core.h"
#include "aiml.h"
using namespace aiml;
using namespace aiml;

/** core options **/
cCoreOptions::cCoreOptions(void) : file_gossip("gossip.txt"), user_file("userlist.xml"), sentence_limit("?!.;"),
  should_trim_blanks(false), allow_system(false), allow_javascript(false), allow_dateformat(false) { }

/** interpreter **/
cInterpreter::cInterpreter(void) : last_error(AIMLERR_NO_ERR), callbacks(NULL) { }
cInterpreter::~cInterpreter(void) { }

AIMLError cInterpreter::getError(void) { return last_error; }

cInterpreter* cInterpreter::newInterpreter(void) {
  return new cCore;
}

void cInterpreter::freeInterpreter(cInterpreter* i) {
  delete i;
}

/** callbacks **/
cInterpreterCallbacks::~cInterpreterCallbacks(void) { }
