

# set the include path found by configure
INCLUDES = $(all_includes)

# the library search path.


lib_LIBRARIES = libaiml.a
libaiml_a_SOURCES = aiml_parser.cpp core.cpp graphmaster.cpp stuff.cpp \
				template_parser.cpp user.cpp errors.cpp caiml_parser.cpp serializer.cpp user_manager.cpp \
		config_parser.cpp javascript.cpp aiml.cpp
libaiml_a_DEPENDENCIES =

pkginclude_HEADERS = errors.h aiml.h




AM_CXXFLAGS = $(WERROR_CXXFLAG) -pedantic -Wall -ansi `xml2-config --cflags`













noinst_HEADERS = aiml_parser.h caiml_parser.h config_parser.h core.h global.h\
	graphmaster.h javascript.h serializer.h user.h user_manager.h
