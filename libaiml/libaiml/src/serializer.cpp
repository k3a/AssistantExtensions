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

#include <netinet/in.h>
#include "global.h"
#include "serializer.h"
using namespace std;
using namespace aiml;

/**
 * cWriteBuffer
 */
cWriteBuffer::cWriteBuffer(void) : pos(0), dont_resize(false) { }

size_t cWriteBuffer::writeString(const std::string& str) {
  size_t start_pos = pos;

  if ((data.size() - pos) < (str.length() + sizeof(size_t)))
    data.resize(data.size() + (str.length() + sizeof(size_t)) - (data.size() - pos));
  
  dont_resize = true;
  if (!writeNumber(str.length())) return 0;
  dont_resize = false;
  
  size_t i = 0;
  while (pos < data.size() && i < str.length()) {
    data[pos] = str[i];
    pos++; i++;
  }
  data.resize(data.size() + str.length() - i);
  while (i < str.length()) {
    data[pos] = str[i];
    pos++; i++;
  }
  
  return (pos - start_pos);
}

size_t cWriteBuffer::writeNumber(size_t num) {
  if (!dont_resize) {
    if ((data.size() - pos) < sizeof(size_t))
      data.resize(data.size() + sizeof(size_t) - (data.size() - pos));
  }
  
  *reinterpret_cast<size_t*>(&data[pos]) = htonl(num);
  
  pos += sizeof(size_t);
  return sizeof(size_t);
}

bool cWriteBuffer::writeToFile(std::ostream& file) const {
  size_t len = data.size();
  return (file.write(reinterpret_cast<const char*>(&len), sizeof(size_t)) && file.write(&data[0], sizeof(char) * data.size()));
}


bool cWriteBuffer::readFromFile(std::istream& file) {
  size_t len;
  if (!file.read(reinterpret_cast<char*>(&len), sizeof(size_t))) return false;
  if (len == 0) return false;

  data.resize(len);
  return file.read(&data[0], len);
}

size_t cWriteBuffer::seek(size_t new_pos, size_t offset) {
  if ((new_pos + offset) > data.size()) return pos;
  // _DBG_CODE(msg_dbg() << "seek to " << new_pos + offset << " was at " << pos << "/" << data.size() << endl);
  size_t old_pos = pos;
  pos = offset + new_pos;
  return old_pos;
}

size_t cWriteBuffer::tell(void) const {
  return pos;
}

bool cWriteBuffer::empty(void) const {
  return data.empty();
}

bool cWriteBuffer::at_end(void) const {
  return (pos == data.size());
}

void cWriteBuffer::clear(void) {
  pos = 0;
  data.clear();
}

/**
 * cReadBuffer
 */
cReadBuffer::cReadBuffer(const cWriteBuffer& wr_buff) : data(wr_buff.data), pos(wr_buff.pos), size(wr_buff.data.size()) { }

size_t cReadBuffer::readString(std::string& str, bool append) {
  size_t len;
  size_t chars_read = readNumber(len);
  _DBG_CODE(msg_dbg() << "length: " << len << endl);
  if (!chars_read) return 0;
  if ((size - pos) < len) return 0;
  
  char* buf = new char[len+1];
  size_t i;
  for (i = 0; i < len; i++, pos++) { buf[i] = data[pos]; }
  buf[i] = '\0';
  if (append) str += buf;
  else str = buf;
  delete buf;
  
  chars_read += i;
  return chars_read;
}
  
size_t cReadBuffer::readNumber(size_t& num) {
  size_t space_left = size - pos;
  if (space_left < sizeof(size_t)) return 0;
  num = ntohl(*(reinterpret_cast<const size_t*>(&data[pos])));
  
  pos += sizeof(size_t);
  return sizeof(size_t);
}

size_t cReadBuffer::discardString(void) {
  size_t len;
  size_t chars_read = readNumber(len);
  if (!chars_read) return 0;
  if ((size - pos) < len) return 0;
  pos += len;
  chars_read += len;
  return chars_read;
}

size_t cReadBuffer::seek(size_t new_pos, size_t offset) {
  if ((new_pos + offset) > size) return pos;
  _DBG_CODE(msg_dbg() << "seek to " << new_pos + offset << " was at " << pos << "/" << size << endl);
  size_t old_pos = pos;
  pos = offset + new_pos;
  return old_pos;
}

size_t cReadBuffer::tell(void) const {
  return pos;
}

bool cReadBuffer::at_end(void) const {
  _DBG_CODE(msg_dbg() << "at_end()? " << pos << "/" << size << endl);
  return (pos == size);
}

void cReadBuffer::to_end(void) {
  pos = size;
}

size_t cReadBuffer::limitSize(size_t _size) {
  size_t old_size = size;
  if ((_size + pos) <= data.size()) size = (_size + pos);
  return old_size;
}

void cReadBuffer::restoreSize(size_t _size) {
  if (_size > data.size()) return;
  size = _size;
}

/**
 * Standard file
 */
bool aiml::writeNumber(ostream& file, size_t n) {
  size_t n2 = htonl(n);
  return file.write(reinterpret_cast<const char*>(&n2), sizeof(size_t));
}

bool aiml::writeString(ostream& file, const string& s) {
  if (!aiml::writeNumber(file, s.length())) return false;
  return file.write(s.c_str(), s.length());
}


bool aiml::readNumber(istream& file, size_t& num) {
  size_t temp;
  if (file.read(reinterpret_cast<char*>(&temp), sizeof(size_t))) {
    num = ntohl(temp);
    return true;
  }
  else { return false; }
}

bool aiml::readString(istream& file, string& out) {
  size_t len;
  if (!aiml::readNumber(file, len)) { _DBG_CODE(msg_dbg() << "couldn't read string length" << endl); return false; }
  if (len == 0) { _DBG_CODE(msg_dbg() << "string of size 0" << endl); return false; }

  char* buf = new char[len+1];
  bool ret = file.read(buf, len);
  buf[len] = '\0';
  
  if (ret) { out = buf; }
  delete buf;
  
  return ret;
}
