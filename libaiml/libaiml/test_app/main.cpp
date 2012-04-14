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
#include <iostream>
#include "../src/aiml.h"

using namespace std;
using std_util::strip;
using namespace aiml;

class cTestAppCallbacks : public cInterpreterCallbacks {
  public:
    void onAimlLoad(const std::string& filename) {
      cout << "Loaded " << filename << endl;
    }
};

int main(int argc, char* argv[]) {
  cInterpreter* interpreter = cInterpreter::newInterpreter();

  int ret = 0;
  
  // exceptions are used because returning in the middle of the program wouldn't let 'interpreter' be freed
  try {
    cTestAppCallbacks myCallbacks;
    interpreter->registerCallbacks(&myCallbacks);
    
    cout << "Initializing interpreter..." << endl;
    if (!interpreter->initialize("libaiml.xml")) throw 1;
    
    string line;
    cout << "Type \"quit\" to... guess..." << endl;

    string result;
    std::list<cMatchLog> log;

    cout << "You: " << flush;
    while (getline(cin, line)) {
      if (strip(line).empty()) { cout << "You: " << flush; continue; }
      if (line == "quit") break;
      
      /** remove the last parameter to avoid logging the match **/
      if (!interpreter->respond(line, "localhost", result, &log)) throw 3;

      cout << "Bot: " << strip(result) << endl;
      cout << "Match path:" << endl;
      for(list<cMatchLog>::const_iterator it_outter = log.begin(); it_outter != log.end(); ++it_outter) {
        cout << "\tpattern:\t";
        for (list<string>::const_iterator it = it_outter->pattern.begin(); it != it_outter->pattern.end(); ++it) { cout << "[" << *it << "] "; }
        cout << endl << "\tthat:\t\t";
        for (list<string>::const_iterator it = it_outter->that.begin(); it != it_outter->that.end(); ++it) { cout << "[" << *it << "] "; }
        cout << endl << "\ttopic:\t\t";
        for (list<string>::const_iterator it = it_outter->topic.begin(); it != it_outter->topic.end(); ++it) { cout << "[" << *it << "] "; }
        cout << endl << endl;
      }
      cout << "You: " << flush;
    }
  
    /** Uncomment this line out and you'll see that the bot will no longer remember user vars **/
    //interpreter->unregisterUser("localhost");
  }
  catch(int _ret) {
    cout << "ERROR: " << interpreter->getErrorStr(interpreter->getError()) << " (" << interpreter->getError() << ")" << endl;
    if (!interpreter->getRuntimeErrorStr().empty()) cout << "Runtime Error: " << interpreter->getRuntimeErrorStr() << endl;
    ret = _ret;
  }

  delete interpreter;
  // the above is equivalent to cInterpreter::freeInterpreter(interpreter);
  return ret;
}
