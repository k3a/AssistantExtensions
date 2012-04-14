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

#include <libxml/tree.h>
#include <libxml/encoding.h>
#include <libxml/xmlwriter.h>
#include <string>
#include <sstream>
#include "core.h"
using namespace aiml;
using namespace std;

cUserManager::cUserManager(cCore& _core) : core(_core)
{
  xml_parser = xmlNewParserCtxt();
}

cUserManager::~cUserManager(void) {
  if (xml_parser) xmlFreeParserCtxt(xml_parser);
}

struct cUserManagerException {
  cUserManagerException(const string& _msg, size_t _line) : msg(_msg), line(_line) { }
  const string msg;
  const size_t line;
};

const string& cUserManager::getRuntimeError(void) {
  return runtime_error;
}

bool cUserManager::load(const std::string& file) {
  bool ret = true;
  xmlDoc* doc = xmlCtxtReadFile(xml_parser, file.c_str(), NULL, 0);
  if (!doc) return false;

  string current_user;
  xmlNode* root = xmlDocGetRootElement(doc);
  if (!root) return false;

  try {
    for (xmlNode* user_node = root->children; user_node; user_node = user_node->next) {
      if (user_node->type != XML_ELEMENT_NODE) continue;
      
      if (string(INV_BAD_CAST(user_node->name)) == "user") {
        if (!user_node->properties) throw cUserManagerException("user with no properties", user_node->line);
        if (string(INV_BAD_CAST(user_node->properties->name)) == "name") {
          current_user = INV_BAD_CAST(user_node->properties->children->content);
          pair<string, cUser> new_user(current_user, cUser(current_user, &core.last_error, &core.botvars_map, &core.graphmaster));
          core.user_map.insert(new_user);
        }
      }
      for (xmlNode* var_node = user_node->children; var_node; var_node = var_node->next) {
        if (var_node->type != XML_ELEMENT_NODE) continue;
        if (string(INV_BAD_CAST(var_node->name)) == "set") {
          if (!var_node->properties) throw cUserManagerException("set with no propierties", var_node->line);
          if (string(INV_BAD_CAST(var_node->properties->name)) == "name") {
            if (!var_node->children) continue;
            core.user_map[current_user].setVar(INV_BAD_CAST(var_node->properties->children->content), INV_BAD_CAST(var_node->children->content));
          }
        }
      }
    }
  }
  catch(const cUserManagerException& exc) {
    ostringstream osstr;
    osstr << exc.line;
    runtime_error = exc.line + " (at line " + osstr.str() + ")";
    ret = false;
  }
  catch(...) {
    runtime_error = "unknown exception";
    ret = false;
  }

  xmlFreeDoc(doc);
  return ret;
}

bool cUserManager::save(const std::string& file) {
  xmlTextWriterPtr writer;
  bool ret = true;

  writer = xmlNewTextWriterFilename(file.c_str(), 0);
  if (!writer) return false;

  xmlTextWriterSetIndent(writer, true);
  xmlTextWriterSetIndentString(writer, BAD_CAST("  "));
  
  try {
    if (xmlTextWriterStartDocument(writer, NULL, NULL, NULL) < 0) throw string("start document error");
    if (xmlTextWriterStartElement(writer, BAD_CAST("userset")) < 0) throw string("start userset error ");

    const cCore::UserMap& user_map = core.user_map;
    for(cCore::UserMap::const_iterator it = user_map.begin(); it != user_map.end(); ++it) {
      if (xmlTextWriterStartElement(writer, BAD_CAST("user")) < 0) throw string("start user error");
      if (xmlTextWriterWriteAttribute(writer, BAD_CAST("name"), BAD_CAST(it->first.c_str())) < 0) throw string("user attribute error");

      const StringMAP& var_map = it->second.getAllVars();
      for(StringMAP::const_iterator var_it = var_map.begin(); var_it != var_map.end(); ++var_it) {
        if (xmlTextWriterStartElement(writer, BAD_CAST("set")) < 0) throw string("start set error");
        if (xmlTextWriterWriteAttribute(writer, BAD_CAST("name"), BAD_CAST(var_it->first.c_str())) < 0) throw string("set attribute error");
        if (xmlTextWriterWriteCDATA(writer, BAD_CAST(var_it->second.c_str())) < 0) throw string("set content error");
        if (xmlTextWriterEndElement(writer) < 0) throw string("end set error");
      }
      if (xmlTextWriterEndElement(writer) < 0) throw string("end user error");
    }

    if (xmlTextWriterEndElement(writer) < 0) throw string("end userset error");
    if (xmlTextWriterEndDocument(writer) < 0) throw string("end document error");
  }
  catch(const string& msg) {
    runtime_error = msg;
    ret = false;
  }
  catch(...) {
    runtime_error = "unknown exception";
    ret = false;
  }
  
  xmlFreeTextWriter(writer);
  return ret;
}
