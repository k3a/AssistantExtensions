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

#ifndef __LIBAIML_CPARSER_H__
#define __LIBAIML_CPARSER_H__

#define CAIML_VERSION_NUMBER    1

#include <string>
#include <fstream>

namespace aiml {

class CAIMLparser {
  public:
    CAIMLparser(cGraphMaster& graphmaster, aiml::AIMLError& errnum);

    bool load(const std::string& filename);
    bool save(const std::string& filename);

  private:
    cGraphMaster& graphmaster;
    aiml::AIMLError& errnum;

    bool readChilds(std::ifstream& file, NodeVec& same_childs, NodeVec& diff_childs, NodeType type);
    bool checkForLeaf(std::ifstream& file, bool& is_leaf);

    bool writeChilds(std::ofstream& file, const NodeVec& same_childs, const NodeVec& diff_childs);
    
    void set_error(aiml::AIMLError _errnum);
};

}

#endif
