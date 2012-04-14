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

#ifndef __LIBAIML_SUBENGINE_JAVASCRIPT_H__
#define __LIBAIML_SUBENGINE_JAVASCRIPT_H__

#include <string>

#include "config.h"
#ifdef ENABLE_JAVASCRIPT
#define XP_UNIX
#include <jsapi.h>
#undef XP_UNIX
#endif

namespace aiml {

  class cJavaScript {
    public:
      cJavaScript(void);
      ~cJavaScript(void);
  
      bool init(void);
      bool eval(const std::string& in, std::string& out);
      const std::string& getRuntimeError(void);
      
    private:
      #ifdef ENABLE_JAVASCRIPT
      struct cJavaScriptInterpreter {
        cJavaScriptInterpreter(void);

        static void ErrorReporter(JSContext* cx, const char* message, JSErrorReport* report);
        static JSBool Print(JSContext* cx, JSObject* obj, uintN argc, jsval* argv, jsval* rval);
  
        JSRuntime* rt;
        JSClass global_class;
      };
      
      cJavaScriptInterpreter* interpreter;
      #endif
      
      std::string runtime_error;
      std::string eval_result;
  };
  
}

#endif // __LIBAIML_SUBENGINE_JAVASCRIPT_H__
