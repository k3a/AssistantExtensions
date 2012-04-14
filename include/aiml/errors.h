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

#ifndef __LIBAIML_ERRORS_H__
#define __LIBAIML_ERRORS_H__


namespace aiml {
  /**
   * Error codes produced by libaiml.
  */
  enum AIMLError {
    // core errors
    AIMLERR_NO_ERR,                   /**< No error. */
    AIMLERR_NO_FILES,                 /**< No aiml files specified to load. */
    AIMLERR_PATT_READERR,             /**< Read error while matching file patterns. */
    AIMLERR_PATT_UNKNOWN,             /**< Unknown error while matching file patterns. */
    AIMLERR_OPEN_GOSSIP,              /**< Couldn't open gossip file for writing. */
    AIMLERR_NOT_INIT,                 /**< The core isn't yet initialized. */
    AIMLERR_ALREADY_INIT,             /**< The core is already initialized. */
    AIMLERR_NO_CFGFILE,               /**< Couldn't open/read configuration file. (use cInterpreter::getRuntimeErrorStr()). */
    AIMLERR_NO_USERLIST,              /**< Error with userlist file. */

    // sub-engines' errors
    AIMLERR_SYSTEM_NOT_ALLOWED,       /**< System tag is not allowed to be executed. */
    AIMLERR_JAVASCRIPT_NOT_ALLOWED,   /**< Javascript tag is not allowed to be executed. */
    AIMLERR_JAVASCRIPT_PROBLEM,       /**< Problem with JavaScript interpreter (use cInterpreter::getRuntimeErrorStr()). */

    // graphmaster errors
    AIMLERR_EMPTY_INPUT,              /**< Normalization of input resulted in empty string. */
    AIMLERR_NO_MATCH,                 /**< No match found for input. */
    AIMLERR_EMPTY_GM,                 /**< Empty graphmaster (no categories loaded). */

    // aiml parser errors
    AIMLERR_AIML_NOOPEN,              /**< Couldn't open aiml file. */
    AIMLERR_AIML_PARSE,               /**< AIML Parser error (use cInterpreter::getRuntimeErrorStr()). */

    // caiml parser errors
    AIMLERR_CAIML_NOMAGIC,            /**< Couldn't retrieve magic number from caiml file. */
    AIMLERR_CAIML_NOTCAIML,           /**< Not a CAIML file. */
    AIMLERR_CAIML_NOOPEN_READ,        /**< Couldn't open CAIML file for reading. */
    AIMLERR_CAIML_NOVERSION,          /**< Couldn't get version from CAIML file. */
    AIMLERR_CAIML_WRONGVERSION,       /**< CAIML file version not supported. */
    AIMLERR_CAIML_NOSIZE,             /**< Couldn't get size of graphmaster (ie: number of templates) from CAIML file. */
    AIMLERR_CAIML_NOCHILDSNUM,        /**< No size of childs for node in CAIML file. */
    AIMLERR_CAIML_NOKEY,              /**< Coulnd't read key for node in CAIML file. */
    AIMLERR_CAIML_NOTEMPLATE,         /**< Coulnd't read template for node in CAIML file. */
    AIMLERR_CAIML_EMPTYGM,            /**< Can't save an empty graphmaster. */
    AIMLERR_CAIML_NOOPEN_WRITE,       /**< Couldn't open CAIML file for writing. */
    AIMLERR_CAIML_INCORRECTSTRUCT,    /**< Caiml file is not correctly built. */

    // template parser errors
    AIMLERR_TEMLP_UNKNOWN_TAG,        /**< Unknown tag found while parsing template. */

    // cUser errors
    AIMLERR_NEG_THAT_INDEX,           /**< Negative index in 'that' tag found. */
    AIMLERR_NEG_INPUT_INDEX,          /**< Negative index in 'input' tag found. */

    // misc
    AIMLERR_MAX
  };
}

#endif
