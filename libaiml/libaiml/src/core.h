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

#ifndef __LIBAIML_CORE_H__
#define __LIBAIML_CORE_H__

#define LIBAIML_POPEN_BUFFER_SIZE   256     // buffer size used when reading data from popen()

#include <string>
#include <fstream>
#include <vector>
#include <list>
#include <map>
#include <std_utils/cconfig.h>

#include "aiml.h"
#include "global.h"
#include "errors.h"
#include "user.h"
#include "serializer.h"
#include "graphmaster.h"
#include "aiml_parser.h"
#include "caiml_parser.h"
#include "user_manager.h"
#include "config_parser.h"
#include "javascript.h"

namespace aiml {
  class cCore : public cInterpreter {
    public:
      cCore(void);
      ~cCore(void);
  
      bool initialize(const std::string& filename);
      bool initialize(const std::string& filename, const cCoreOptions& opts);
      void deinitialize(void);

      void registerCallbacks(cInterpreterCallbacks* callbacks);
  
      bool respond(const std::string& input, const std::string& username, std::string& output, std::list<cMatchLog>* log = NULL);
      void unregisterUser(const std::string& user_id);
  
      bool learnFile(const std::string& filename);
  
      bool saveGraphmaster(const std::string& file);
      bool loadGraphmaster(const std::string& file);
  
      std::string getErrorStr(AIMLError error_num);
      std::string getRuntimeErrorStr(void);
  
    private:
      friend class aiml::cGraphMaster;
      friend class aiml::cUserManager;
      friend class aiml::cConfigParser;
      
      /** Error handling **/
      static std::string error_str[AIMLERR_MAX];
      void set_error(AIMLError);
  
      /** Utility Functions **/
      bool load_aiml_files(void);
      bool learn_file(const std::string& filename, bool at_runtime = false);
  
      bool doSystemCall(const std::string& cmd, std::string& ret);
  
      /** java script **/
      bool doJavaScriptCall(const std::string& cmd, std::string& ret);
      cJavaScript javascript_interpreter;
  
      const std::string& getBotVar(const std::string& key) const;
      StringMAP botvars_map;
      
      /** Internal modules **/
      cGraphMaster graphmaster;
      AIMLparser aiml_parser;
      CAIMLparser caiml_parser;
      
      /** Configuration options/vars **/
      cConfigParser cfg_parser;
      cCoreOptions cfg_options;
      std_util::cConfig cfg;
      bool applyConfigOptions(void);
      
      std::ofstream file_gossip_stream;
      
      /** User management **/
      cUserManager user_manager;
      typedef std::map<std::string,aiml::cUser> UserMap;
      UserMap user_map;
      
      /** other **/
      bool initialized;
  };
}

#endif  // __LIBAIML_CORE_H__
