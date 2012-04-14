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

#include <sstream>
#include <string>
#include <std_utils/std_util.h>
#include <libxml/tree.h>
#include "core.h"
using namespace std;
using namespace stdu;
using namespace aiml;

/* exception struct */
struct cConfigParserException {
  cConfigParserException(const string& _msg, size_t _line) : msg(_msg), line(_line) { }
  const string msg;
  const size_t line;
};

cConfigParser::cConfigParser(cCore& _core) : core(_core) {
  xml_parser = xmlNewParserCtxt();
}

cConfigParser::~cConfigParser(void) {
  if (xml_parser) xmlFreeParserCtxt(xml_parser);
}

const string& cConfigParser::getRuntimeError(void) {
  return runtime_error;
}

bool cConfigParser::load(const std::string& file, bool dont_fill_options) {
  bool ret = true;
  xmlDoc* doc = xmlCtxtReadFile(xml_parser, file.c_str(), NULL, 0);
  if (!doc) return false;

  string current_user;
  xmlNode* root = xmlDocGetRootElement(doc);
  if (!root) return false;

  try {
    for (xmlNode* user_node = root->children; user_node; user_node = user_node->next) {
      if (user_node->type != XML_ELEMENT_NODE) continue;

      if (string(INV_BAD_CAST(user_node->name)) == "botvars") parseBotVars(user_node->children);
      else if (string(INV_BAD_CAST(user_node->name)) == "substitutions") parseSubstitutions(user_node->children);
      else if (string(INV_BAD_CAST(user_node->name)) == "options" && !dont_fill_options) parseOptions(user_node->children);
    }
  }
  catch(const cConfigParserException& exc) {
    ostringstream osstr;
    osstr << exc.line;
    runtime_error = exc.msg + " (at line " + osstr.str() + ")";
    ret = false;
  }
  catch(...) {
    runtime_error = "unknown exception";
    ret = false;
  }

  xmlFreeDoc(doc);
  return ret;

}


void cConfigParser::parseBotVars(xmlNode* list) {
  for (xmlNode* node = list; node; node = node->next) {
    if (node->type != XML_ELEMENT_NODE) continue;
    if (string(INV_BAD_CAST(node->name)) == "set") {
      if (!node->properties) throw cConfigParserException("parseBotVars: set with no properties", node->line);
      if (string(INV_BAD_CAST(node->properties->name)) == "name") {
        if (!node->children) continue;
        core.botvars_map[INV_BAD_CAST(node->properties->children->content)] = INV_BAD_CAST(node->children->content);
      }
    }
  }
}

void cConfigParser::parseSubstitutions(xmlNode* list) {
  for (xmlNode* node = list; node; node = node->next) {
    if (node->type != XML_ELEMENT_NODE) continue;
    string elem_name(INV_BAD_CAST(node->name));
    if (elem_name == "person") parseSubstitutionsEntry(node->children, cGraphMaster::SubsTypePerson);
    else if (elem_name == "person2") parseSubstitutionsEntry(node->children, cGraphMaster::SubsTypePerson2);
    else if (elem_name == "gender") parseSubstitutionsEntry(node->children, cGraphMaster::SubsTypeGender);
    else if (elem_name == "normalization") parseSubstitutionsEntry(node->children, cGraphMaster::SubsTypeGeneral);
  }
}

void cConfigParser::parseSubstitutionsEntry(xmlNode* list, cGraphMaster::SubsType sub_type) {
  for (xmlNode* node = list; node; node = node->next) {
    if (node->type != XML_ELEMENT_NODE) continue;
    
    string elem_name(INV_BAD_CAST(node->name));
    bool use_regex = false;
    if (elem_name == "substitution") {
      if (!node->children) continue;
      string from, to;
      for (xmlNode* sub_node = node->children; sub_node; sub_node = sub_node->next) {
        if (sub_node->type != XML_ELEMENT_NODE) continue;

        /* parse from */
        if (string(INV_BAD_CAST(sub_node->name)) == "from") {
          use_regex = false;
          if (sub_node->properties && sub_node->properties->children) {
            if (string(INV_BAD_CAST(sub_node->properties->name)) == "type" &&
                string(INV_BAD_CAST(sub_node->properties->children->content)) == "regex") { use_regex = true; }
          }
          if (!sub_node->children || !sub_node->children->content)
            throw cConfigParserException("parseSubstitutionEntry: from with no content", sub_node->line);
          from = string(INV_BAD_CAST(sub_node->children->content));
        }

        /* parse to */
        else if (string(INV_BAD_CAST(sub_node->name)) == "to") {
          if (!sub_node->children || !sub_node->children->content) to.clear();
          else to = string(INV_BAD_CAST(sub_node->children->content));
          if (from.empty()) throw cConfigParserException("parseSubstitutionEntry: from with no content at </to>", sub_node->line);
          try { core.graphmaster.addSubstitution(from, to, sub_type, use_regex); }
          catch(const string& msg) { throw cConfigParserException(msg, sub_node->line); }
        }
      }
    }
  }
}

void cConfigParser::parseOptions(xmlNode* list) {
  core.cfg_options.should_trim_blanks = false;
  core.cfg_options.allow_dateformat = false;
  core.cfg_options.allow_javascript = false;
  core.cfg_options.allow_system = false;
  
  for (xmlNode* node = list; node; node = node->next) {
    if (node->type != XML_ELEMENT_NODE) continue;

    string elem_name(INV_BAD_CAST(node->name));
    if (elem_name == "file_patterns") {
      if (!node->children || !node->children->content) continue;
      string content(INV_BAD_CAST(node->children->content));
      core.cfg_options.file_patterns = strip(content, "\n\r\t");
    }
    else if (elem_name == "file_gossip") {
      if (!node->children || !node->children->content) throw cConfigParserException("parseOptions: gossip with no content", node->line);
      else {
        string content(INV_BAD_CAST(node->children->content));
        core.cfg_options.file_gossip = strip(content, "\n\r\t");
      }
    }
    else if (elem_name == "user_file") {
      if (!node->children || !node->children->content) throw cConfigParserException("parseOptions: user_file with no content", node->line);
      else {
        string content(INV_BAD_CAST(node->children->content));
        core.cfg_options.user_file = strip(content, "\n\r\t");
      }
    }
    else if (elem_name == "sentence_limit") {
      if (!node->children || !node->children->content) throw cConfigParserException("parseOptions: sentence_limit with no content", node->line);
      else {
        string content(INV_BAD_CAST(node->children->content));
        core.cfg_options.sentence_limit = content;
      }
    }
    else if (elem_name == "trim_blanks") core.cfg_options.should_trim_blanks = true;
    else if (elem_name == "allow") {
      for (xmlNode* sub_node = node->children; sub_node; sub_node = sub_node->next) {
        if (sub_node->type != XML_ELEMENT_NODE) continue;
        elem_name = INV_BAD_CAST(sub_node->name);
        if (elem_name == "javascript") core.cfg_options.allow_javascript = true;
        else if (elem_name == "system") core.cfg_options.allow_system = true;
        else if (elem_name == "dateformat") core.cfg_options.allow_dateformat = true;
      }
    }
  }

}
