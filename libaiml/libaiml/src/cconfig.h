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
#ifndef __STD_UTILS_CCONFIG_H__
#define __STD_UTILS_CCONFIG_H__

#include <string>
#include <fstream>
#include <map>

#ifndef CONF_MAX_LINE_LENGTH
#define CONF_MAX_LINE_LENGTH 2048
#endif

/**
 * \class std_util::cConfig
 * This class allows your program to read configuration files which store data in key-value pairs. Once you open the configuration file, this class
 * parses it, stores all key-value definitions in an internal map and the closes the file. After that you can start inquiring the value associated to keys
 * (if defined, using GetKeyValue()) and interpret them as different types (a number, a boolean or a string).
 * If you rather perform operations on the internal map yourself, you can ask for this map (read-only) and do whatever you want with it.
 *
 */

namespace std_util {

  /**
   * Type thrown as exception on certaing cConfig function.
   */
  class cConfigException {
    public:
      enum cConfigExceptionType {
        CCFGEX_KEYNOTFOUND,         /**< Requested key wasn't found. */
        CCFGEX_CANNOTOPEN,          /**< Couldn't open/read config file. */
        CCFGEX_MALFORMED            /**< Malformed config file. */
      };

      cConfigExceptionType getType(void) const;
      const std::string& getMsg(void) const;

    private:
      friend class cConfig;
      cConfigException(void);
      cConfigException(const std::string& msg, cConfigExceptionType type);
      
      std::string msg;
      cConfigExceptionType type;
  };

  class cConfig {
    public:
      /** indicates the error "level". \see setErrorLevel and cConfig(ERRLEV lev) */
      enum ERRLEV { ERRLEV_EXCEPTIONS, ERRLEV_CERR, ERRLEV_QUIET };
      
      cConfig(void);
      cConfig(ERRLEV lev);
    
      bool Open(const std::string& file_str);
  
      bool GetKeyValue(const std::string& key_name, std::string& value) const;
      bool GetKeyValue(const std::string& key_name, signed short& value) const;
      bool GetKeyValue(const std::string& key_name, unsigned short& value) const;
      bool GetKeyValue(const std::string& key_name, unsigned int& value) const;
      bool GetKeyValue(const std::string& key_name, signed int& value) const;
      bool GetKeyValue(const std::string& key_name, unsigned long& value) const;
      bool GetKeyValue(const std::string& key_name, signed long& value) const;
      bool GetKeyValue(const std::string& key_name, bool& value) const;
      bool GetKeyValue(const std::string& key_name, double& value) const;
      bool GetKeyValue(const std::string& key_name, float& value) const;

      bool isKey(const std::string& key_name) const;
  
      void setErrorLevel(ERRLEV lev);

      /** the type used by cConfig to represent the config file in memory. */
      typedef std::map<std::string, std::string> StringMAP;

      /** allows you to read the internal map of key-value's. */
      const StringMAP& exposeData(void) const { return var_map; }
    
    private:
      bool Parse(void);
      bool ParseLine(const std::string& line, std::string& key_name, std::string& key_value);

      void giveError(const std::string& err_str, cConfigException::cConfigExceptionType type) const;

      StringMAP var_map;
      ERRLEV error_level;

      std::ifstream file_stream;
  };

};

namespace stdu = std_util;

#endif  // __STD_UTILS_CCONFIG_H__
