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
#include <fstream>
#include <glob.h>
#include "core.h"
#include "config.h"

using namespace std;
using namespace aiml;
using std_util::gettok;
using std_util::operator<<;

cCore::cCore(void) :
          graphmaster(file_gossip_stream, last_error, *this),
          aiml_parser(graphmaster, last_error), caiml_parser(graphmaster, last_error),
          cfg_parser(*this),
          cfg(std_util::cConfig::ERRLEV_QUIET), user_manager(*this), initialized(false)
{ }
          
cCore::~cCore(void) { deinitialize(); }

bool cCore::initialize(const std::string& filename) {
  if (initialized) { set_error(AIMLERR_ALREADY_INIT); return false; }
  if (!cfg_parser.load(filename)) { set_error(AIMLERR_NO_CFGFILE); return false; }
  return applyConfigOptions();
}

bool cCore::initialize(const std::string& filename, const cCoreOptions& opts) {
  if (initialized) { set_error(AIMLERR_ALREADY_INIT); return false; }
  if (!cfg_parser.load(filename, true)) { set_error(AIMLERR_NO_CFGFILE); return false; }
  cfg_options = opts;
  return applyConfigOptions();
}

void cCore::deinitialize(void) {
  if (!initialized) return;
  
  if (file_gossip_stream.is_open()) file_gossip_stream.close();
  user_manager.save(cfg_options.user_file);
  initialized = false;
}

void cCore::registerCallbacks(cInterpreterCallbacks* _callbacks) {
  callbacks = _callbacks;
}

void cCore::unregisterUser(const std::string& user_id) {
  UserMap::iterator it = user_map.find(user_id);
  if (it != user_map.end()) user_map.erase(it);
}

bool cCore::learnFile(const std::string& filename) {
  if (!initialized) { set_error(AIMLERR_NOT_INIT); return false; }
  return learn_file(filename, true);
}

bool cCore::saveGraphmaster(const std::string& file) {
#ifdef ENABLE_CAIML
  if (!initialized) { set_error(AIMLERR_NOT_INIT); return false; }
  return caiml_parser.save(file);
#else
  return false;
#endif
}

bool cCore::loadGraphmaster(const std::string& file) {
#ifdef ENABLE_CAIML
  if (!initialized) { set_error(AIMLERR_NOT_INIT); return false; }
  return caiml_parser.load(file);
#else
  return false;
#endif
}

bool cCore::respond(const std::string& input, const std::string& username, std::string& output, std::list<cMatchLog>* log) {
  if (!initialized) { set_error(AIMLERR_NOT_INIT); return false; }
  
  vector<string> sentences;
  graphmaster.normalize(input, sentences);
  if (sentences.empty()) { set_error(AIMLERR_EMPTY_INPUT); return false; }

  UserMap::const_iterator user_it = user_map.find(username);
  if (user_it == user_map.end()) {
    pair<string, cUser> user_entry(username, cUser(username, &last_error, &botvars_map, &graphmaster));
    user_map.insert(user_entry);
  }

  /* CHANGE: if (getAnswer() == FALSE) ==> the user's input vector will be filled with unanswered inputs */
  cUser& user = user_map[username];
  user.addUserInput(sentences);

  string single_response;
  output.clear();
  if (log) log->clear();

  for (vector<string>::const_iterator it = sentences.begin(); it != sentences.end(); ++it) {
    if (!graphmaster.getAnswer(*it, user, single_response, log)) return false;
    output += single_response + " ";
  }

  vector<string> split_response;
  do_split(output, split_response, cfg_options.sentence_limit, false);
  user.addBotThat(split_response);
  return true;
}

/*********************************** PRIVATE ******************************************/
bool cCore::applyConfigOptions(void) {
  srand(time(NULL));

  file_gossip_stream.open(cfg_options.file_gossip.c_str());
  if (!file_gossip_stream) { set_error(AIMLERR_OPEN_GOSSIP); return false; }

  if (!user_manager.load(cfg_options.user_file)) { set_error(AIMLERR_NO_USERLIST); return false; }

  if (cfg_options.allow_javascript) {
    if (!javascript_interpreter.init()) {
      if (last_error == AIMLERR_NO_ERR) set_error(AIMLERR_JAVASCRIPT_PROBLEM);
      return false;
    }
  }

  if (!load_aiml_files()) { return false; }
  graphmaster.sort_all();

  initialized = true;
  return true;
}

/**
 * Tell the aiml parser to feed the graphmaster
 */
bool cCore::load_aiml_files(void) {
  string full_token;
  list<string> patterns_vec;

  // create vector from string
  for (size_t i = 1; true; i++) {
    string partial_token;
    if (!std_util::gettok(cfg_options.file_patterns, partial_token, i)) break;
    
    if (!partial_token.empty() && partial_token[partial_token.length()-1] == '\\') full_token += (partial_token + ' ');
    else {
      full_token += partial_token;
      patterns_vec.push_back(full_token);
      full_token.clear();
    }
  }
  if (!full_token.empty()) patterns_vec.push_back(full_token);
  if (patterns_vec.empty()) return true;

  // glob all patterns
  glob_t matching_glob;
  for (std::list<string>::const_iterator it = patterns_vec.begin(); it != patterns_vec.end(); ++it) {
    int ret = glob(it->c_str(), GLOB_ERR | GLOB_NOSORT | (it == patterns_vec.begin() ? 0 : GLOB_APPEND), NULL, &matching_glob);
    if (ret != 0) {
      if (ret == GLOB_ABORTED) set_error(AIMLERR_PATT_READERR);
      else if (ret == GLOB_NOMATCH) continue;
      else set_error(AIMLERR_PATT_UNKNOWN);
      globfree(&matching_glob);
      return false;
    }
  }

  // get matching files
  list<string> matching_files;
  if (matching_glob.gl_pathc == 0) { set_error(AIMLERR_NO_FILES); return false; }
  for (size_t i = 0; i < matching_glob.gl_pathc; i++) {
    matching_files.push_back(matching_glob.gl_pathv[i]);
  }
  globfree(&matching_glob);

  // load matching files
  for (list<string>::const_iterator it = matching_files.begin(); it != matching_files.end(); it++) {
    if (!learn_file(*it)) return false;
    else { if (callbacks) callbacks->onAimlLoad(*it); }
  }
  return true;
}

/**
 * Loads AIML code from a file and feed it to the graphmaster
 */
bool cCore::learn_file(const string& filename, bool at_runtime) {
  return aiml_parser.parse(filename, cfg_options.should_trim_blanks, at_runtime);
}

bool cCore::doSystemCall(const string& cmd, string& out) {
  if (!cfg_options.allow_system) {
    set_error(AIMLERR_SYSTEM_NOT_ALLOWED);
    return false;
  }

  out.clear();
  FILE* file = popen(cmd.c_str(), "r");
  if (file) {
    char input[LIBAIML_POPEN_BUFFER_SIZE];
    while (!ferror(file) && !feof(file)) {
      size_t bytes_read = fread(input, 1, LIBAIML_POPEN_BUFFER_SIZE-1, file);
      if (bytes_read > 0) { input[bytes_read] = '\0'; out += input; }
    }
    pclose(file);
  }

  return true;
}

bool cCore::doJavaScriptCall(const std::string& cmd, std::string& ret) {
  if (!cfg_options.allow_javascript) {
    set_error(AIMLERR_JAVASCRIPT_NOT_ALLOWED);
    return false;
  }
  else {
    bool success = javascript_interpreter.eval(cmd, ret);
    if (!success) last_error = AIMLERR_JAVASCRIPT_PROBLEM;
    return success;
  }
}

/**
 * Debugging stuff
 */
#ifdef _DEBUG
#include <iostream>

std::ostream& aiml::msg_dbg(bool add_prefix) {
  if (add_prefix) return cout << "libaiml: [DEBUG] ";
  else return cout;
}

#endif
