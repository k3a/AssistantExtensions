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
#include <libxml/parserInternals.h>
#include "core.h"

using namespace std;
using namespace aiml;
using std_util::strip;

/** handlers **/
namespace aiml {
  void startElementHandler(void* ctx, const xmlChar* localname, const xmlChar* prefix, const xmlChar* URI,
    int nb_namespaces, const xmlChar** namespaces, int nb_attributes, int nb_defaulted, const xmlChar** attr)
  {
    list<string> attr_list;
    for (int i = 0; i < nb_attributes * 5; i += 5) {
      attr_list.push_back(INV_BAD_CAST(attr[i]));
      attr_list.push_back(string(INV_BAD_CAST(attr[i+3]), (size_t)(attr[i+4]-attr[i+3])));
    }
    static_cast<AIMLparser*>(ctx)->startElement(INV_BAD_CAST(localname), attr_list);
  }

  void endElementHandler(void* ctx, const xmlChar* localname, const xmlChar* prefix, const xmlChar* URI)
  {
    static_cast<AIMLparser*>(ctx)->endElement(INV_BAD_CAST(localname));
  }

  void endElementHandlerOld(void* ctx, const xmlChar* name) { static_cast<AIMLparser*>(ctx)->endElement(INV_BAD_CAST(name)); }
  void characterDataHandler(void* ctx, const xmlChar* s, int len) { static_cast<AIMLparser*>(ctx)->characters(string(INV_BAD_CAST(s), 0, len), len); }
  void errorHandler(void* ctx, const char* msg, ...) { static_cast<AIMLparser*>(ctx)->onError(); }
}

/** constructor / destructor **/
AIMLparser::AIMLparser(cGraphMaster& _gm, AIMLError& _errnum) : graphmaster(_gm), errnum(_errnum) { }

AIMLparser::~AIMLparser(void) { }

/**
 * public functions
 */
bool AIMLparser::parse(const std::string& filename, bool _trim_blanks, bool at_runtime) {
  // init vars
  trim_blanks = _trim_blanks;
  insert_ordered = at_runtime;
  verbatim = false;
  level = LEVEL_OTHER;
  last_char_offset = -1;
  ignore_chardata = false;
  inside_blanks = false;
  binary_pos = 0;
  offset_stack = stack<size_t>();
  runtime_error.clear();

  // set handlers again
  xmlSAXHandler xml_handler;
  memset(&xml_handler, 0, sizeof(xmlSAXHandler));
  xml_handler.startElementNs  = aiml::startElementHandler;
  xml_handler.endElementNs    = aiml::endElementHandler;
  xml_handler.characters      = aiml::characterDataHandler;
  xml_handler.cdataBlock      = aiml::characterDataHandler;
  xml_handler.error           = aiml::errorHandler;
  xml_handler.fatalError      = aiml::errorHandler;
  xml_handler.initialized     = XML_SAX2_MAGIC;

  // create a context
  xml_context = xmlCreateFileParserCtxt(filename.c_str());
  if (!xml_context) {
    set_error(aiml::AIMLERR_AIML_PARSE);
    xmlErrorPtr err = xmlCtxtGetLastError(xml_context);
    if (err) runtime_error = err->message;
    else runtime_error = "couldn't get a parsing context";
    return false;
  }
  
  xmlSAXHandlerPtr old_sax = xml_context->sax;
  xml_context->sax = &xml_handler;
  xml_context->userData = this;

  bool ret = true;
  if (xmlParseDocument(xml_context) < 0 || errnum == aiml::AIMLERR_AIML_PARSE) {
    set_error(aiml::AIMLERR_AIML_PARSE);
    /* watch if runtime_error is set and deal accordingly */
    ret = false;
  }

  // and reset stuff
  xml_context->sax = old_sax;
  if (xml_context->myDoc) xmlFreeDoc(xml_context->myDoc);
  xmlFreeParserCtxt(xml_context);
  topic.clear(); that.clear(); patt.clear(); templ.clear();
  return ret;
}

std::string AIMLparser::getRuntimeError(void) {
  return runtime_error;
}

/**
 * private interface
 */

void AIMLparser::set_error(AIMLError _errnum) { errnum = _errnum; }

void AIMLparser::onError(void) {
  if (runtime_error.empty()) {
    xmlErrorPtr err = xmlCtxtGetLastError(xml_context);
    if (err) {
      ostringstream osstr;
      osstr << err->line << ":" << err->int2 << ")";
      runtime_error = strip(err->message, '\n', std_util::RIGHT) + string(" (at ") +
          (err->file ? string(err->file) + string(":") : string("")) + osstr.str();
    }
    else runtime_error = "unknown error while parsing";
  }
  set_error(aiml::AIMLERR_AIML_PARSE);
  xmlStopParser(xml_context);
  return;
}

void AIMLparser::trim_multiple_blanks(const string& text, string& templ, int len) {
  size_t text_len = text.length();
  if (text_len > templ.capacity()) templ.reserve(text_len);

  for (size_t pos = 0; pos < text_len; ++pos) {
    if (!inside_blanks) {
      if (text[pos] == ' ' || text[pos] == '\t' || text[pos] == '\r' || text[pos] == '\n') { inside_blanks = true; templ += ' '; }
      else templ += text[pos];
    }
    else {
      if (text[pos] != ' ' && text[pos] != '\t' && text[pos] != '\r' && text[pos] != '\n') {
        inside_blanks = false;
        templ += text[pos];
      }
    }
  }
}

void AIMLparser::characters(const std::string& text, int len) {
  // _DBG_CODE(msg_dbg() << "CDATA[" << text << "]" << endl);

  switch (level) {
    case LEVEL_INSIDE_PATTERN: patt += text; break;
    case LEVEL_INSIDE_THAT: that += text; break;
    case LEVEL_INSIDE_TEMPLATE:
    {
      if (ignore_chardata) break;

      if (trim_blanks && !verbatim) {
        string chardata;
        trim_multiple_blanks(text, chardata, len);

        if (!chardata.empty()) {
          binary_pos += templ.writeNumber(0);   // dummy length
          binary_pos += templ.writeNumber(TEMPL_CHARACTERS);
          binary_pos += templ.writeString(chardata);
        }
      }
      else {
        if (!text.empty()) {
          binary_pos += templ.writeNumber(0);   // dummy length
          binary_pos += templ.writeNumber(TEMPL_CHARACTERS);
          binary_pos += templ.writeString(text);
        }
      }
    }
    break;
    case LEVEL_OTHER:
    break;
  }
}

void AIMLparser::startElement(const std::string& name, const list<string>& attr_list) {
  inside_blanks = false;
  // _DBG_CODE(msg_dbg() << "<" << name << ">" << endl);

  if (level == LEVEL_OTHER) {
    if (name == "aiml") { }
    else if (name == "topic") {
      if (attr_list.empty() || attr_list.front() != "name") {
        _DBG_CODE(msg_dbg() << __LINE__ << endl);
        xmlStopParser(xml_context);
      }
      else {
        list<string>::const_iterator it = attr_list.begin();
        topic = *++it;
      }
    }
    else if (name == "category");
    else if (name == "pattern") level = LEVEL_INSIDE_PATTERN;
    else if (name == "that") level = LEVEL_INSIDE_THAT;
    else if (name == "template") level = LEVEL_INSIDE_TEMPLATE;
  }
  else if (level == LEVEL_INSIDE_TEMPLATE) {
    offset_stack.push(binary_pos);
    binary_pos += templ.writeNumber(0);     // write dummy length

    /*** CONDITION ***/
    if (name == "condition") {
      string type, pred_name, value;
      bool has_name = false;
      bool has_value = false;

      ignore_chardata = true;
      binary_pos += templ.writeNumber(TEMPL_CONDITION);

      for (list<string>::const_iterator it = attr_list.begin(); it != attr_list.end(); ++it) {
        if (*it == "xsi:type") type = *++it;
        else if (*it == "name") { has_name = true; pred_name = *++it; }
        else if (*it == "value") { has_value = true; value = *++it; }
      }

      if (type.empty()) {
        if (!has_name) type = "multiPredicateCondition";
        else if (!has_value) type = "singlePredicateCondition";
        else type = "blockCondition";
      }

      if (type == "blockCondition") {
        binary_pos += templ.writeNumber(TEMPL_CONDITION_BLOCK);
        binary_pos += templ.writeString(strip(pred_name));
        binary_pos += templ.writeString(strip(value));
      }
      else if (type == "singlePredicateCondition") {
        binary_pos += templ.writeNumber(TEMPL_CONDITION_SINGLE);
        binary_pos += templ.writeString(strip(pred_name));
      }
      else { binary_pos += templ.writeNumber(TEMPL_CONDITION_MULTI); }
    }

    /*** STAR && TOPICSTAR && THATSTAR ***/
    else if (name == "star" || name == "topicstar" || name == "thatstar") {
      size_t index = 1;
      if (!attr_list.empty() && attr_list.front() == "index") {
        list<string>::const_iterator it = attr_list.begin();
        istringstream istr(std_util::strip(*++it));
        if (!(istr >> index)) index = 1;
      }
      if (name == "star") { binary_pos += templ.writeNumber(TEMPL_STAR); }
      else if (name == "topicstar") { binary_pos += templ.writeNumber(TEMPL_TOPICSTAR); }
      else if (name == "thatstar") { binary_pos += templ.writeNumber(TEMPL_THATSTAR); }
      binary_pos += templ.writeNumber(index);
    }

    /***    THAT && INPUT   ***/
    else if (name == "that" || name == "input") {
      size_t index1 = 1, index2 = 1;
      if (!attr_list.empty() && attr_list.front() == "index") {
        list<string>::const_iterator it = attr_list.begin();
        string parm = *++it;
        istringstream istr1(stdu::gettok(parm, 1, false, ','));
        istringstream istr2(stdu::gettok(parm, 2, false, ','));
        if (!(istr1 >> index1)) { index1 = 1; }
        else { if (!(istr2 >> index2)) { index2 = 1; } }
      }

      binary_pos += templ.writeNumber(name == "that" ? TEMPL_THAT : TEMPL_INPUT);
      binary_pos += templ.writeNumber(index1) + templ.writeNumber(index2);
    }

    /***    GET && BOT && SET   ***/
    else if (name == "get" || name == "bot" || name == "set") {
      string pred;
      if (!attr_list.empty() && attr_list.front() == "name") {
        list<string>::const_iterator it = attr_list.begin();
        pred = std_util::strip(*++it);
      }
      else { _DBG_CODE(msg_dbg() << "at line: " << __LINE__ << endl); xmlStopParser(xml_context); return; }

      if (name == "get") { binary_pos += templ.writeNumber(TEMPL_GET); }
      else if (name == "bot") { binary_pos += templ.writeNumber(TEMPL_BOT); }
      else if (name == "set") { binary_pos += templ.writeNumber(TEMPL_SET); }
      binary_pos += templ.writeString(pred);
    }

    /*** LI ***/
    else if (name == "li") {
      binary_pos += templ.writeNumber(TEMPL_LI);
      ignore_chardata = false;

      string type, name, value;
      bool has_name = false;
      bool has_value = false;

      for (list<string>::const_iterator it = attr_list.begin(); it != attr_list.end(); ++it) {
        if (*it == "xsi:type") type = *++it;
        else if (*it == "name") { has_name = true; name = *++it; }
        else if (*it == "value") { has_value = true; value = *++it; }
      }

      if (type.empty()) {
        if (!has_value) type = "defaultListItem";
        else if (!has_name) type = "valueOnlyListItem";
        else type = "nameValueListItem";
      }

      if (type == "nameValueListItem") {
        binary_pos += templ.writeNumber(TEMPL_LI_NAME_VALUE);
        binary_pos += templ.writeString(strip(name));
        binary_pos += templ.writeString(strip(value));
      }
      else if (type == "valueOnlyListItem") {
        binary_pos += templ.writeNumber(TEMPL_LI_VALUE);
        binary_pos += templ.writeString(strip(value));
      }
      else if (type == "defaultListItem") {
        binary_pos += templ.writeNumber(TEMPL_LI_DEFAULT);
      }
      else { _DBG_MARK(); xmlStopParser(xml_context); return; }
    }

    /*** other ***/
    else if (name == "uppercase") { binary_pos += templ.writeNumber(TEMPL_UPPERCASE); }
    else if (name == "lowercase") { binary_pos += templ.writeNumber(TEMPL_LOWERCASE); }
    else if (name == "formal") { binary_pos += templ.writeNumber(TEMPL_FORMAL); }
    else if (name == "sentence") { binary_pos += templ.writeNumber(TEMPL_SENTENCE); }
    else if (name == "random") { ignore_chardata = true; binary_pos += templ.writeNumber(TEMPL_RANDOM); }
    else if (name == "gossip") { binary_pos += templ.writeNumber(TEMPL_GOSSIP); }
    else if (name == "srai") { binary_pos += templ.writeNumber(TEMPL_SRAI); }
    else if (name == "think") { binary_pos += templ.writeNumber(TEMPL_THINK); }
    else if (name == "learn") { binary_pos += templ.writeNumber(TEMPL_LEARN); }
    else if (name == "system") { binary_pos += templ.writeNumber(TEMPL_SYSTEM); verbatim = true; }
    else if (name == "javascript") { binary_pos += templ.writeNumber(TEMPL_JAVASCRIPT); verbatim = true; }

    /*** Possible shortcuts: for now they aren't, if they are shortcuts this ids will be changed later ***/
    else if (name == "person") { binary_pos += templ.writeNumber(TEMPL_PERSON); }
    else if (name == "person2") { binary_pos += templ.writeNumber(TEMPL_PERSON2); }
    else if (name == "gender") { binary_pos += templ.writeNumber(TEMPL_GENDER); }

    /***    EMPTY TAGS    ***/
    else if (name == "sr") { binary_pos += templ.writeNumber(TEMPL_SR); }
    else if (name == "date") {
      string format;
      if (!attr_list.empty() && attr_list.front() == "format") {
        list<string>::const_iterator it = attr_list.begin();
        format = *++it;
      }
      binary_pos += templ.writeNumber(TEMPL_DATE) + templ.writeString(format);
    }
    else if (name == "id") { binary_pos += templ.writeNumber(TEMPL_ID); }
    else if (name == "size") { binary_pos += templ.writeNumber(TEMPL_SIZE); }
    else if (name == "version") { binary_pos += templ.writeNumber(TEMPL_VERSION); }

    /*** unrecognized tag ***/
    else { binary_pos += templ.writeNumber(TEMPL_UNKNOWN); }
  }
}


void AIMLparser::endElement(const std::string& name) {
  inside_blanks = false;
  // _DBG_CODE(msg_dbg() << "</" << name << ">" << endl);

  if (level == LEVEL_OTHER) {
    if (name == "aiml") { }
    else if (name == "topic") {
      topic.clear();
    }
    else if (name == "category") {
      AIMLentry entry;
      clean_pattern(that); clean_pattern(topic); clean_pattern(patt);
      tokenizeToList(strip(that), entry.that, true, "*");
      tokenizeToList(strip(topic), entry.topic, true, "*");
      tokenizeToList(strip(patt), entry.patt, true, "*");
      entry.templ = templ;
      // _DBG_CODE(msg_dbg() << "PAT[" << patt << "] THAT[" << that << "] TOPIC[" << topic << "]" << endl);
      graphmaster.addEntry(entry, insert_ordered);
      that.clear(); patt.clear(); templ.clear();
    }
  }
  else if (level == LEVEL_INSIDE_THAT) { if (name == "that") level = LEVEL_OTHER; }
  else if (level == LEVEL_INSIDE_PATTERN) { if (name == "pattern") level = LEVEL_OTHER; }
  else if (level == LEVEL_INSIDE_TEMPLATE) {
    if (name == "template") {
      if (templ.empty()) {
        templ.writeNumber(0);   // dummy length
        templ.writeNumber(TEMPL_CHARACTERS);
        templ.writeString("");
      }
      binary_pos = 0;
      level = LEVEL_OTHER;
    }
    else {
      if (name == "system" || name == "javascript") verbatim = false;
      else if (name == "condition" || name == "random") ignore_chardata = false;
      else if (name == "li") ignore_chardata = true;

      // retrieve and discard starting position of tag
      size_t start_pos = offset_stack.top();
      offset_stack.pop();

      // shortcut elements check (if the current offset didn't moved past header, it doesn't have any content)
      if ((binary_pos - start_pos) == sizeof(size_t) * 2) {
        if (name == "person" || name == "person2" || name == "gender") {

          size_t type_pos = templ.seek(start_pos + sizeof(size_t));      // skip length field
          if (name == "person") templ.writeNumber(TEMPL_PERSON_SHORT);
          else if (name == "person2") templ.writeNumber(TEMPL_PERSON2_SHORT);
          else if (name == "gender") templ.writeNumber(TEMPL_GENDER_SHORT);
          templ.seek(type_pos);
        }
      }

      // write the length of tag in the template leaving the pointer where it was
      size_t curr_offset = templ.seek(start_pos);
      templ.writeNumber(binary_pos - start_pos);
      templ.seek(curr_offset);
    }
  }
}

