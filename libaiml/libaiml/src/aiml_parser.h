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

#ifndef __LIBAIML_PARSER_H__
#define __LIBAIML_PARSER_H__

#include <list>
#include <string>
#include <stack>
#include <libxml/parser.h>

namespace aiml {
  class cGraphMaster;

  enum BinTemplType {
    TEMPL_CONDITION, TEMPL_CHARACTERS, TEMPL_STAR, TEMPL_TOPICSTAR, TEMPL_THATSTAR, TEMPL_THAT,
    TEMPL_INPUT, TEMPL_GET, TEMPL_BOT, TEMPL_SET, TEMPL_LI, TEMPL_LOWERCASE, TEMPL_UPPERCASE, TEMPL_FORMAL,
    TEMPL_SENTENCE, TEMPL_RANDOM, TEMPL_GOSSIP, TEMPL_SRAI, TEMPL_THINK, TEMPL_LEARN, TEMPL_SYSTEM,
    TEMPL_JAVASCRIPT, TEMPL_SR, TEMPL_DATE, TEMPL_SIZE, TEMPL_VERSION, TEMPL_ID,
    TEMPL_PERSON, TEMPL_PERSON2, TEMPL_GENDER,
    TEMPL_PERSON_SHORT, TEMPL_PERSON2_SHORT, TEMPL_GENDER_SHORT,
    TEMPL_UNKNOWN
  };
  
  enum BinTemplCondType {
    TEMPL_CONDITION_SINGLE, TEMPL_CONDITION_MULTI, TEMPL_CONDITION_BLOCK
  };
  
  enum BinTemplLiType {
    TEMPL_LI_NAME_VALUE, TEMPL_LI_VALUE, TEMPL_LI_DEFAULT
  };

  class AIMLparser {
    public:
      AIMLparser(cGraphMaster& graphmaster, aiml::AIMLError& errnum);
      ~AIMLparser(void);
      
      bool parse(const std::string& filename, bool trim_blanks, bool at_runtime);
      std::string getRuntimeError(void);
      
    private:
      cGraphMaster& graphmaster;
      
      aiml::AIMLError& errnum;
      void set_error(aiml::AIMLError _errnum);
      std::string runtime_error;
  
      void close(void);

      friend void startElementHandler(void* ctx, const xmlChar* localname, const xmlChar* prefix, const xmlChar* URI,
          int nb_namespaces, const xmlChar** namespaces, int nb_attributes, int nb_defaulted, const xmlChar ** attr);
      friend void endElementHandler(void* ctx, const xmlChar* localname, const xmlChar* prefix, const xmlChar* URI);
      friend void startElementHandlerOld(void* ctx, const xmlChar* name, const xmlChar** attr);
      friend void endElementHandlerOld(void* ctx, const xmlChar* name);
      friend void characterDataHandler(void* ctx, const xmlChar* s, int len);
      friend void errorHandler(void* ctx, const char* msg, ...);
    
      void startElement(const std::string& name, const std::list<std::string>& attr_list);
      void endElement(const std::string& name);
      void characters(const std::string& text, int len);
      void onError(void);
      
      std::string topic, that, patt;
      cWriteBuffer templ;
  
      void trim_multiple_blanks(const std::string& text, std::string& templ, int len);
      int last_char_offset;
      bool inside_blanks;
      bool ignore_chardata;
      bool trim_blanks;
  
      enum PARSING_LEVEL { LEVEL_OTHER, LEVEL_INSIDE_PATTERN, LEVEL_INSIDE_TEMPLATE, LEVEL_INSIDE_THAT };
      PARSING_LEVEL level;
      
      xmlParserCtxtPtr xml_context;
      bool insert_ordered;
      bool verbatim;

      bool inside_random;
      std::stack<size_t> li_count_stack;
      
      std::stack<size_t> offset_stack;
      size_t binary_pos;
  };

}

#endif
