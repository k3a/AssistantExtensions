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

#ifndef __LIBAIML_SERIALIZER_H__
#define __LIBAIML_SERIALIZER_H__

#include <iostream>
#include <string>

namespace aiml {
  class cWriteBuffer {
    public:
      cWriteBuffer(void);
    
      size_t writeString(const std::string& str);
      size_t writeNumber(size_t num);

      size_t seek(size_t new_pos, size_t offset = 0);
      size_t tell(void) const;
      bool at_end(void) const;
      bool empty(void) const;

      bool readFromFile(std::istream& file);
      bool writeToFile(std::ostream& file) const;

      void clear(void);
      
    private:
      friend class cReadBuffer;
      
      std::vector<char> data;
      size_t pos;
      bool dont_resize;
  };

  class cReadBuffer {
    public:
      cReadBuffer(const cWriteBuffer& wr_buff);
          
      size_t readString(std::string& str, bool append = false);
      size_t readNumber(size_t& num);
  
      size_t discardString(void);
      
      size_t seek(size_t new_pos, size_t offset = 0);
      size_t tell(void) const;
      bool at_end(void) const;

      size_t limitSize(size_t _size);
      void restoreSize(size_t _size);
      void to_end(void);

    private:
      cReadBuffer(void);

      const std::vector<char>& data;
      size_t pos, size;
  };

  // for CAIML
  bool writeString(std::ostream& file, const std::string& str);
  bool readChardata(std::ostream& file, std::vector<char>& s);
  bool writeNumber(std::ostream& file, size_t num);

  bool readString(std::istream& file, std::string& str);
  bool writeChardata(std::ostream& file, const std::vector<char>& s);
  bool readNumber(std::istream& file, size_t& num);
}

#endif
