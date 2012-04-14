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

#include <iostream>
#include <sstream>
#include <fstream>
#include "cconfig.h"
#include "std_util.h"
using namespace std_util;
using std::string;
using std::ifstream;
using std::istringstream;

/**
 * default constructor.
 * Default is to throw errors as exceptions.
 */
cConfig::cConfig(void) : error_level(ERRLEV_EXCEPTIONS) { }

/**
 * custom error type constructor.
 * Choose the method to throw errors.
 */
cConfig::cConfig(ERRLEV lev) : error_level(lev) { }

/**
 * You can use this function to set the error reporting type: exceptions, standard error or quiet.
 * \param lev is the error "level"
 */
void cConfig::setErrorLevel(ERRLEV lev) { error_level = lev; }

/**
 * use this function to open the configuration file.
 * \param file_str is a path to the file in question.
 * \returns true iif file was opened and parsed succesfully.
 * This function may return an exception if setErrorLevel() is set to do so.
 */
bool cConfig::Open(const string& file_str) {
  file_stream.open(file_str.c_str());
  if (!file_stream) { giveError("Error opening config file", cConfigException::CCFGEX_CANNOTOPEN); file_stream.close(); return false;  }
  if (!Parse()) { giveError("Malformed .conf file", cConfigException::CCFGEX_MALFORMED); file_stream.close(); return false; }
  file_stream.close();
  return true;
}

bool cConfig::Parse(void) {
  char line[CONF_MAX_LINE_LENGTH];
  string str_line, key_name, key_value;
  while(file_stream.getline(line,CONF_MAX_LINE_LENGTH-2)) {
    str_line = line;
    if (ParseLine(std_util::strip(str_line),key_name,key_value)) var_map[key_name] = key_value;
  }
  return true;
}

bool cConfig::ParseLine(const string& line, string& key_name, string& key_value) {
  using std_util::strip;
  if (line[0] == '#') return false;
  string formatted_line(strip(strip(line,'\n',std_util::RIGHT),'\r',std_util::RIGHT));
  
  size_t equal_pos = formatted_line.find('=');
  if (equal_pos == string::npos || equal_pos == 0) return false;
  key_name = strip(formatted_line.substr(0,equal_pos));
  if (key_name.empty()) return false;
  key_value = strip(formatted_line.substr(equal_pos+1));

  return true;
}


/**
 * allows you to know if a key was defined in the configuration file or not.
 * \param key_name is the name of the key.
 * \returns true iif key is defined
 */
bool cConfig::isKey(const std::string& key_name) const {
  return (var_map.find(key_name) != var_map.end());
}

/* Until 'export' keyword is not implemented, I will not use templates }=\ */

/**
 * Retrieve the value of a key.
 * \param key_name is the name of the key.
 * \param value will contain the value of the given key.
 * \returns true if the value was retrieved succesfully.
 * This function may return an exception (std_util::cConfigException) if setErrorLevel() is set to do so.
 * The rest of the overloaded functions with this name perform exactly the same.
 */
bool cConfig::GetKeyValue(const std::string& key_name, std::string& value) const {
  StringMAP::const_iterator it = var_map.find(key_name);
  if (it == var_map.end()) { giveError(string("KeyNotFound: [") + key_name + string("]"), cConfigException::CCFGEX_KEYNOTFOUND); return false; }
  value = strip(it->second);
  return true;
}
    
bool cConfig::GetKeyValue(const std::string& key_name, unsigned short& value) const {
  StringMAP::const_iterator it = var_map.find(key_name);
  if (it == var_map.end()) { giveError(string("KeyNotFound: [") + key_name + string("]"), cConfigException::CCFGEX_KEYNOTFOUND); return false; }
  istringstream stream(it->second);
  stream >> value;
  return true;
}

bool cConfig::GetKeyValue(const std::string& key_name, signed short& value) const {
  StringMAP::const_iterator it = var_map.find(key_name);
  if (it == var_map.end()) { giveError(string("KeyNotFound: [") + key_name + string("]"), cConfigException::CCFGEX_KEYNOTFOUND); return false; }
  istringstream stream(it->second);
  stream >> value;
  return true;
}
    
bool cConfig::GetKeyValue(const std::string& key_name, unsigned int& value) const {
  StringMAP::const_iterator it = var_map.find(key_name);
  if (it == var_map.end()) { giveError(string("KeyNotFound: [") + key_name + string("]"), cConfigException::CCFGEX_KEYNOTFOUND); return false; }
  istringstream stream(it->second);
  stream >> value;
  return true;
}

bool cConfig::GetKeyValue(const std::string& key_name, signed int& value) const {
  StringMAP::const_iterator it = var_map.find(key_name);
  if (it == var_map.end()) { giveError(string("KeyNotFound: [") + key_name + string("]"), cConfigException::CCFGEX_KEYNOTFOUND); return false; }
  istringstream stream(it->second);
  stream >> value;
  return true;
}

bool cConfig::GetKeyValue(const std::string& key_name, signed long& value) const {
  StringMAP::const_iterator it = var_map.find(key_name);
  if (it == var_map.end()) { giveError(string("KeyNotFound: [") + key_name + string("]"), cConfigException::CCFGEX_KEYNOTFOUND); return false; }
  istringstream stream(it->second);
  stream >> value;
  return true;
}

bool cConfig::GetKeyValue(const std::string& key_name, unsigned long& value) const {
  StringMAP::const_iterator it = var_map.find(key_name);
  if (it == var_map.end()) { giveError(string("KeyNotFound: [") + key_name + string("]"), cConfigException::CCFGEX_KEYNOTFOUND); return false; }
  istringstream stream(it->second);
  stream >> value;
  return true;
}

bool cConfig::GetKeyValue(const std::string& key_name, float& value) const {
  StringMAP::const_iterator it = var_map.find(key_name);
  if (it == var_map.end()) { giveError(string("KeyNotFound: [") + key_name + string("]"), cConfigException::CCFGEX_KEYNOTFOUND); return false; }
  istringstream stream(it->second);
  stream >> value;
  return true;
}

bool cConfig::GetKeyValue(const std::string& key_name, double& value) const {
  StringMAP::const_iterator it = var_map.find(key_name);
  if (it == var_map.end()) { giveError(string("KeyNotFound: [") + key_name + string("]"), cConfigException::CCFGEX_KEYNOTFOUND); return false; }
  istringstream stream(it->second);
  stream >> value;
  return true;
}

    
bool cConfig::GetKeyValue(const std::string& key_name, bool& value) const {
  StringMAP::const_iterator it = var_map.find(key_name);
  if (it == var_map.end()) { giveError(string("KeyNotFound: [") + key_name + string("]"), cConfigException::CCFGEX_KEYNOTFOUND); return false; }
  istringstream stream(it->second);
  stream >> std::boolalpha >> value;
  return true;
}

void cConfig::giveError(const string& error_str, cConfigException::cConfigExceptionType type) const {
  switch (error_level) {
    case ERRLEV_EXCEPTIONS:
      throw cConfigException(error_str, type);
    break;
    case ERRLEV_CERR:
      std::cerr << "cConfig: " << error_str << std::endl;
    break;
    case ERRLEV_QUIET:
      /* do nothing */
    break;
  }
}

/**
 * cConfigException definition
 */
cConfigException::cConfigException(void) { }
cConfigException::cConfigException(const std::string& _msg, cConfigExceptionType _type) : msg(_msg), type(_type) { }

/**
 * returns the type of error ocurred when the exception was thrown.
 */
cConfigException::cConfigExceptionType cConfigException::getType(void) const {
  return type;
}
 
/**
 * returns the error message associated with the type returned by getType().
 */
const std::string& cConfigException::getMsg(void) const {
  return msg;
}
