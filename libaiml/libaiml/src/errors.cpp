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
#include <string>
#include "core.h"

using namespace aiml;
using namespace aiml;

std::string cCore::error_str[AIMLERR_MAX] = {
  "No Error",

  // core errors
  "No .aiml files to load", "Read error while matching file patterns", "Unknown error while matching file patterns",
  "Can't create/access gossip file", "Core isn't initialized", "Core is already initialized",
  "Error while parsing configuration file", "Error with userlist file",

  // sub-engines' errors
  "System tag is not allowed to be executed",
  "Javascript tag is not allowed to be executed",
  "Problem with JavaScript interpreter",

  // graphmaster errors
  "Normalization on input resulted in empty string",
  "No match found. There should be at least a pickup line (<pattern>*<that>*<topic>*)",
  "The GraphMaster was empty (no AIML data was loaded)",

  // aiml parser errors
  "Couldn't open aiml file",
  "AIML parser error",

  // caiml parser errors
  "Couldn't read magic number from caiml file", "File was not a caiml file (magic number mismatch)",
  "Couldn't open caiml file for reading", "No caiml version found in file",
  "Unsupported/Incorrect caiml version", "No graphmaster size in caiml file",
  "No size of childs for node in caiml file", "No key for node in caiml file",
  "No template for node in caiml file", "Can't save an empty graphmaster",
  "Couldn't open caiml file for writing",
  "Caiml file is not correctly built",

  // template parser errors
  "Unknown tag found while parsing template",

  // cUser errors
  "Negative index in <that> found",
  "Negative index in <input> found"
};

void cCore::set_error(AIMLError err) { last_error = err; }

std::string cCore::getErrorStr(AIMLError error_num) {
  return (error_num == AIMLERR_MAX ? "" : error_str[error_num]);
}

std::string cCore::getRuntimeErrorStr(void) {
  if (last_error == AIMLERR_NO_CFGFILE) return cfg_parser.getRuntimeError();
  else if (last_error == AIMLERR_AIML_PARSE) return aiml_parser.getRuntimeError();
  else if (last_error == AIMLERR_NO_USERLIST) return user_manager.getRuntimeError();
  else if (last_error == AIMLERR_JAVASCRIPT_PROBLEM) return javascript_interpreter.getRuntimeError();
  else return std::string();
}
