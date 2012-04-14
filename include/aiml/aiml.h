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

#ifndef __LIBAIML_AIML_H__
#define __LIBAIML_AIML_H__

#include <string>
#include <list>
#include "errors.h"

/**
 * Namespace that holds the libaiml public interface.
 */
namespace aiml {
  /**
   * This structure is used to hold the nodes of the tree that matched the user's input, that and topic.
   * The lists hold one token (ie, a word with no spaces) of the corresponding match.
   */
  struct cMatchLog {
    std::list<std::string> pattern, that, topic;
  };

  /** Options to configure the interpreter. */
  struct cCoreOptions {
    /**
     * Default constructor.
     * This gives the default values to each of the parameters in this structure.
     * Refer to the configuration file description to see which are those defaults.
     */
    cCoreOptions(void);
    
    std::string file_patterns;    /**< Space separated list of patterns of aiml files to be loaded. */
    std::string file_gossip;      /**< The path where to gossip (a file). */
    std::string user_file;        /**< File where user's data is saved. */
    std::string sentence_limit;   /**< Characters used to separate sentences. */
    bool should_trim_blanks;      /**< If the interpreter should treat multiple whitespace combinations as a single space. */
    bool allow_system;            /**< If the interpreter should execute commands from \<system> tags. */
    bool allow_javascript;        /**< If the interpreter should execute code from \<javascript> tags. */
    bool allow_dateformat;        /**< If the interpreter should format date using the "format" parameter. */
  };

  /**
   * This structure is used to receive notifications of events that libaiml generates.
   * You could derive this class and then pass 'this' to cInterpreter::registerCallbacks().
   * None of these functions should block libaiml, they should return as soon as possible.
   */
  class cInterpreterCallbacks {
    public:
      virtual ~cInterpreterCallbacks(void);

      /**
       * This function is called during initialization, for each aiml file that is loaded.
       * \param filename is the full path to the aiml file just loaded.
       */
      virtual void onAimlLoad(const std::string& filename) = 0;
  };

  /**
   * libaiml interpreter.
   * This is the class to be used as the interface. It encapsulates the libaiml interpreter.
   */
  class cInterpreter {
    public:
      /** Initializes everything. */
      cInterpreter(void);

      /** Deinitialize the core. Calls deinitialize(). */
      virtual ~cInterpreter(void);

      /**
       * Initialize the AIML core using configuration file.
       * \param filename is a path to the configuration file that libaiml uses.
       * \returns true iif initialization was successful
       */
      virtual bool initialize(const std::string& filename) = 0;

      /**
       * Initialize the AIML core using data passed from client program.
       * \param filename is the path to the libaiml configuration file (the \<options> tag is ignored)
       * \param opts is the structure containing the values wanted for each option available.
       * \returns true iif initialization was successful
       */
      virtual bool initialize(const std::string& filename, const cCoreOptions& opts) = 0;

      /**
       * Deinitialize the core.
       * Saves all user variables into the user's files and shuts everything down.
       * You don't have to call this explicitly, the destructor does it.
       */
      virtual void deinitialize(void) = 0;

      /** Register callbacks for libaiml to use. */
      virtual void registerCallbacks(cInterpreterCallbacks* callbacks) = 0;

      /**
       * responder function.
       * The output is touched iif the function returns true. The username will be created if this function is called
       * for the first time with such parameter. The matching & response will be done inside the user's context.
       * If the log parameter is used, it is used to store each of the matches made by the interpreter to reach the template.
       * It is a list because it includes the top-level match and any possible internal \<srai> matches made later.
       * \param input is the input that should be passed to the aiml interpreter.
       * \param username is the username or id that should be asociated with the conversation.
       * \param output is a reference to a string where the interpreter saves the response.
       * \param log is an optional pointer to a list to be used to store cMatchLog structures (user should provide the storage).
       * \returns true iif no errors were found.
       */
      virtual bool respond(const std::string& input, const std::string& username, std::string& output, std::list<cMatchLog>* log = NULL) = 0;

      /**
       * Removes a user from the list in memory.
       * \param username is the user's name as passed to respond().
       */
      virtual void unregisterUser(const std::string& username) = 0;

      /**
       * loads an .aiml file.
       * \param filename is the path (relative to client program) of the aiml file to load.
       * \returns if it was successful.
       */
      virtual bool learnFile(const std::string& filename) = 0;

      /**
       * Saves currently loaded graphmaster into a .caiml file.
       * \param file is the name of the file.
       * \returns if saving was succesful.
       */
      virtual bool saveGraphmaster(const std::string& file) = 0;

      /**
       * Loads a previously saved .caiml file into the core.
       * This functions replaces the content of the graphmaster completely, so
       * if you want to mix aiml files and ONE .caiml file (more wouldn't make sense),
       * you should load all .aiml files first.
       * \param file is the name of the file.
       * \returns if loading was succesful.
       */
      virtual bool loadGraphmaster(const std::string& file) = 0;

      /** Get the last error set. */
      AIMLError getError(void);

      /**
       * get the last error code generated in humanly readable form.
       * \param error_num is the error to interpret (you can take getError() output for this).
       */
      virtual std::string getErrorStr(AIMLError error_num) = 0;

      /**
       * returns the last runtime error message set by the corresponding subsystem.
       * \returns the runtime error or an empty string if none was generated.
       */
      virtual std::string getRuntimeErrorStr(void) = 0;

      /**
       * Create a new interpreter instance.
       * This is necessary because cInterpreter is an abstract interface, you couldn't build
       * the interpreter yourself without seeing the implementation. The data returned is dynamically
       * allocated with 'new', so you can call destroy on it afterwards.
       * \returns a pointer to the newly allocated interpreter object.
       */
      static cInterpreter* newInterpreter(void);

      /**
       * Destroy a cInterpreter object.
       * You don't need to use this as you can just do 'delete i;'. This function
       * is just defined for simmetry.
       */
      static void freeInterpreter(cInterpreter* i);
  
    protected:
      AIMLError last_error;
      cInterpreterCallbacks* callbacks;
  };
}

#endif
