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
#include "javascript.h"
#include "config.h"
#include "global.h"

using namespace std;
using namespace aiml;

/**  Interpreter Instance Data  **/
#ifdef ENABLE_JAVASCRIPT
cJavaScript::cJavaScriptInterpreter::cJavaScriptInterpreter(void) {
  JSClass global_class_template = {
    "global", 0,
    JS_PropertyStub, JS_PropertyStub, JS_PropertyStub, JS_PropertyStub,
    JS_EnumerateStub, JS_ResolveStub, JS_ConvertStub, JS_FinalizeStub
  };
  global_class = global_class_template;
}

void cJavaScript::cJavaScriptInterpreter::ErrorReporter(JSContext* cx, const char* message, JSErrorReport* report) {
  ostringstream osstr;
  osstr << report->lineno;
  string& runtime_error = static_cast<cJavaScript*>(JS_GetContextPrivate(cx))->runtime_error;
  if (runtime_error.empty()) runtime_error = string("JavaScript Error: ") + message + " (at line " + osstr.str() + ")";
}

JSBool cJavaScript::cJavaScriptInterpreter::Print(JSContext* cx, JSObject* obj, uintN argc, jsval* argv, jsval* rval) {
  string& retval = static_cast<cJavaScript*>(JS_GetContextPrivate(cx))->eval_result;
  for (uintN i = 0; i < argc; i++) {
    JSString* str = JS_ValueToString(cx, argv[i]);
    if (!str) return JS_FALSE;
    retval += (i == 0 ? string("") : string(" ")) + string(JS_GetStringBytes(str), JS_GetStringLength(str));
  }
  return JS_TRUE;
}  
#endif

/** Initialization / Destruction **/
cJavaScript::cJavaScript(void) {
#ifdef ENABLE_JAVASCRIPT
  interpreter = NULL;
#endif
}

cJavaScript::~cJavaScript(void) {
#ifdef ENABLE_JAVASCRIPT
  if (interpreter) {
    if (interpreter->rt) JS_DestroyRuntime(interpreter->rt);
  }
  delete interpreter;
#endif
}

bool cJavaScript::init(void) {
#ifdef ENABLE_JAVASCRIPT
  interpreter = new cJavaScriptInterpreter;
  interpreter->rt = JS_NewRuntime(8L * 1024L * 1024L);
  if (!interpreter->rt) return false;
#endif
  return true;
}

/** Evaluation **/
bool cJavaScript::eval(const std::string& in, std::string& out) {
#ifdef ENABLE_JAVASCRIPT
  bool success = true;

  // initialize context
  JSContext* cx = NULL;
  try {
    cx = JS_NewContext(interpreter->rt, 8192);
    if (!cx) return false;
        
    JS_SetContextPrivate(cx, this);
    JS_SetErrorReporter(cx, &cJavaScriptInterpreter::ErrorReporter);
        
    JSObject* global = JS_NewObject(cx, &interpreter->global_class, NULL, NULL);
    if (!global) throw string("no global object");
        
    if (!JS_InitStandardClasses(cx, global)) throw string("couldn't init standard classes");

    if (!JS_DefineFunction(cx, global, "print", &cJavaScriptInterpreter::Print, 0, 0))
      throw string("couldn't init print() function");
        
    // interpret script
    jsval retval;
    eval_result.clear();
    if (JS_EvaluateScript(cx, global, in.c_str(), in.length(), "none", 0, &retval)) {
      JSString* ret_jsstring = JS_ValueToString(cx, retval);
      if (ret_jsstring) out = eval_result;
      else throw string("couldn't get result as string");
    }
    else throw string("evaluation error");
  }
  catch(const std::string& msg) {
    if (runtime_error.empty()) runtime_error = msg;
    success = false;
  }
  catch(...) {
    if (runtime_error.empty()) runtime_error = "unknown exception";
    success = false;
  }

  // free stuff
  if (cx) JS_DestroyContext(cx);

  return success;
#else
  runtime_error = "no JavaScript support";
  return false;
#endif
}

const string& cJavaScript::getRuntimeError(void) {
  return runtime_error;
}

