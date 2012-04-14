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

#ifndef __LIBAIML_USER_H__
#define __LIBAIML_USER_H__

#define LIBAIML_MAX_THAT_SIZE       8      // number of bot responses to keep
#define LIBAIML_MAX_INPUTS_SAVED    16     // the amount of clients input to store

namespace aiml {

  class cGraphMaster;
  
  class cUser {
    public:
      cUser(void);
      cUser(const std::string& _name, aiml::AIMLError* last_error, const StringMAP* botvars, const cGraphMaster* gm);
          
      std::vector<std::string> that_array[LIBAIML_MAX_THAT_SIZE];
      std::vector<std::string> input_array[LIBAIML_MAX_INPUTS_SAVED];
  
      StringMAP vars_map;
      std::string name;
  
      const std::string& setVar(const std::string& key, const std::string& value);
          
      const std::string& getVar(const std::string& key) const;      /** ADD: default values **/
      const StringMAP& getAllVars(void) const;
      const std::string& getBotVar(const std::string& key) const;
  
      const std::string& getInput(unsigned int idx1 = 1, unsigned int idx2 = 1) const;
      const std::string& getThat(bool for_matching = true, unsigned int which = 1, unsigned int sentence = 1) const;
      const std::string& getTopic(void) const;
  
      void addUserInput(std::vector<std::string> input);
      void addBotThat(const std::vector<std::string>& that);
  
      void getMatchList(NodeType type, std::list<std::string>& out) const;
  
      void set_error(aiml::AIMLError errnum) const;
              
    private:
      const StringMAP* botvars_map;
      const cGraphMaster* graphmaster;
      aiml::AIMLError* const last_error;
  };

}

#endif
