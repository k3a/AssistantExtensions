:: libaiml :: by V01D
=====================
NOTE: Don't forget to check the ChangeLog for any important changes and the INSTALL file

1. Intro

	This is a C++ AIML interpreter written from scrath. It uses the STL to avoid reinventing the
wheel. This project started as a fork of "Hippe". I was looking really hard for any usable &
linux compatible C/C++ interpreter for one of my other projects ("imp", an IRC bot, check it out
at my site) and after asking a lot in the alicebot mailing list someone told me I should implement
my own. I didn't wanted to do it at first, but later I realized that noone was going to
mantain any of the agonizing projects I found ("J-Alice", inactive, "ProgramN", just for windoze,
"CyN", idem, "Hippe", as dead as its name infers, "ainebot", didn't use regular AIML files,
and so on). This was really frustrating but I finally managed to do my "libaiml".
	
2. About the name

	At first I gave this project the name "Geeky" (for obvious reasons) but I didn't used any
"Hippie" code at all. I started hacking "Hippie"'s sources (BTW, It wasn't pretty, specially
the new/delete issues) and slowly started to avoid it and to implement my own code. Maybe
I ended up using some similar variable names and ideas but I don't think it goes beyond there
so I don't I need to give credit for that (If I'm wrong please someone correct me).
	After wiping Hippie's sources from my project I renamed it "libaiml", as it sounds like
a general-purpose interpreter.
	
3. Library Interface
	The library is intended to be used as static library. An example application will be compiled
together with libaiml (test_app). So check the main.cpp and you'll realize that there's no
complication in its use. The interface is similar to Hippie and J-Alice. I'll be trying to
keep this main.cpp file commented and free of unnecessary code. 
	libaiml uses a .xml to store configuration data. Check this file out ("libaiml.xml.dist"),
adapt it to your needs, and rename it to 'libaiml.xml' so you can try the test application.
	
4. Library usage & configuration file

	Before you can use libaiml you must create a configuration file (an example "libaiml.xml.dist"
file is shipped with the test_app). The client program must pass the filename (a path) of the 
configuration file to libaiml.
	In this configuration file you tell libaiml information about which .aiml files to load and
the paths to the files it requires (among other options).
  Read this supplied example file, it is commented so you can get an idea of every section.

	You will also need to set a userlist file. Again, in test_app/ there's
already a file that you should use for your own projects. This file is read at
startup and written at shutdown. It is used to store all registered usernames
and their variables with their values. You shouldn't need to touch this file.
	
4. Portability

	Altough I wanted to do a portable library (at least amongst Windoze OSs) I currently don't
have the intention to do it unless someone offers to. I don't think there's much Linux/POSIX
dependant code on it.
	I have a Windoze OS installed on my development box but I never run it, so I won't do any
windoze development. You can always try to compile it with MingW under windoze (using the 
MinSYS framework).
	If you try to compile this under MSYS/Cygwin and some code gives you problems, you can
send me a notice and tell me. I will try to see if I can change that into something portable
if I consider there's a clean easy way to do it.
	
5.	About me, V01D
	If you find any bug, any possibility of optimization (a reasonable one) or any
suggestion/question, you can contact me at omicron(at)omicron(dot)cjb(dot)net. You can find
 more info about ways of contacting me at my site: http://omicron.ig3.net (if the 
site doesn't respond its because the DNS record wasn't updated already, try again later).

6. Final Notes
	When sending a bug it would be useful if you point me where exactly in the code is the bug
(if you know the cause). If you don't know the cause and you just see some unexpected behavior,
you can send me the AIML code (only the necessary fragments to reproduce the error).
	Anyway, don't try sending my big AIML files if they can be downloaded from somehwere else.
	Also, note that the interpreter expects well-formed AIML code (consider that its precondition).
  You can check for xml well-formed'ness using 'xmlwf' (comes with libexpat)
or with xmllint (comes with libxml2). All XML parser assume to some degree
that the document is valid. Therefore, I'll add validity check in future
releases.

APENDIX A: Using the AAA set
	The AAA set uses a feature that I didn't wanted to implement. This feature allows a <get> to
return "OM" for unset variables. I consider this unnecessary as I implemented a way to test
vars for being set or unset (using a condition value ""). So to use the AAA you should add
this line to Stack.aiml:
	<category><pattern>POPOM</pattern><template><srai>POPOM OM</srai></template></category>
  This modification is already done with the shipped .aiml files.

APENDIX B: Some AIML interpreter design decisions
	* unset variables and conditions: some interpreters return "OM" or something like that 
	when you <get> an unset variable. libaiml will return a blank string ("") in this case. You
	can test a variable for being unset using a blank ("") value inside a condition tag, eg:
		<condition name="tested_var" value="">will match this if 'tested_var' is 
		unset</condition>
	This feature works using <li> tag also.
	* If trim_blanks is off, AIML code will be interpreted as-it-is (newlines and everything will
	be used when outputting. Because I don't like this behavior (but I don't like to force this
	either), you can set trim_blanks to "true" and newlines, tabs and spaces will be taken as a
	single space.
	When a response is printed it is always stripped from leading and trailing spaces.
	* <date/> tag returns the system's formatted date (as returned by ctime()). If you wan't
	to use the formatting option which some interpreters use, you need to set
  "allow_formatdate" option to "true". Otherwise the "format" parameter is
  ignored, and the output of ctime() is used.
  This format parameter should be a string indicating a format with the syntax
  defined for the strftime() C function.
  * predicate names and predicate values are stripped from leading and
  trailing spaces. This helps to avoid unwanted spaces as a product of tag
  separation in .aiml files. This decision shouldn't bring any problems, but
  if you feel this shouldn't be like this tell me so and I will consider
  making it optional or removing it.
	
APENDIX B: CAIML
  CAIML is a file format (see CAIML file) that is being slowly introduced into
libaiml. This file format defines a way to write (read into) the graphmaster
to (from) a file.
  The intention of this file format is to reduce the time consumed by parsing
AIML files whenever the libaiml core is started. Once all aiml files are
parsed the first time, it is possible to save the resulting graphmaster into a
file with almost no time penalty. After doing that, it is no longer necessary
to load the aiml files one by one. The loading of the caiml file is
considerably faster (reduced to 1s (vs 7s, doing normal XML parsing),
when tested on the AAA set).
  The idea is that the file is like a graphmaster dump (or "undump", when
reading from the file). This means that loading a caiml file and then loading
one or more aiml files is OK, but loading one or more caiml files after the
first will result in a graphmaster containing only the last caiml file loaded.
  To merge aiml files into a caiml file you FIRST load the caiml file, then
the aiml files, and finally save the resulting graphmaster. To merge two or
more caiml files you actually need to have the aiml files that were used to
create the corresponding graphmasters (well, from all the graphmasters but
one, which would be the caiml file to load before anything else).
  Current implementation works as expected, so testing is encouraged.
  
  To enable caiml code (read/write capabilities) you need to configure libaiml
with the '--enable-caiml' flag. If you don't, the corresponding read/write
funtions will compiled as stubs that always return false.

APENDIX C: JavaScript
  JavaScript integration (using Mozilla's SpiderMonkey JavaScript interpreter)
is included. You can enable it at compile time by using --enable-javascript.
  To use <javascript> you should the 'print' function to return a value.
  For example: 
    <javascript>if (a == b) print("yes");</javascript>
  would return "yes" if variable a equals variable b.
  The 'print' function can take an indefinite number of arguments, the result is
  the concatenation of the passed values with a single space ' '.
  For example:
    <javascript>print("yes", "no");</javascript>
  results in: "yes no".

APENDIX D: Whitespace handling
  Besides being able to specify wether white space should be reduced to single
spaces in the configuration file, the interpretation of white space inside
sub-engines (ie: engines that are supported by libaiml, like shell (<system>),
JavaScript, etc) is different: it is always verbatim.
  This means that newlines will be passed to the sub-engine, allowing (in the
case of <shell> or <javascript>, for example, to not use ';' to separate
expressions. For example:
  <javascript>
    a = 1
    if (a == 1) print("yes")
  </javascript>
  
  is the same as <javascript>a = 1; if (a == 1) print("yes");</javascript>
