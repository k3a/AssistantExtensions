# libaiml for iPhone
# Makefile based on rpetrich's libspeex-iphone

include theos/makefiles/common.mk

SOURCE_PATH = ./libaiml/src/
STDUTILS_PATH = ./std_utils-0.7.5/src/

ARCHS = armv7 armv6
OPTFLAG = -Os
GO_EASY_ON_ME=1

LIBRARY_NAME = libaiml

libaiml_FILES = $(SOURCE_PATH)cconfig.cpp $(SOURCE_PATH)std_utils.cpp $(SOURCE_PATH)aiml.cpp $(SOURCE_PATH)aiml_parser.cpp $(SOURCE_PATH)caiml_parser.cpp $(SOURCE_PATH)config_parser.cpp $(SOURCE_PATH)core.cpp $(SOURCE_PATH)errors.cpp $(SOURCE_PATH)graphmaster.cpp $(SOURCE_PATH)javascript.cpp $(SOURCE_PATH)serializer.cpp $(SOURCE_PATH)stuff.cpp $(SOURCE_PATH)template_parser.cpp $(SOURCE_PATH)user.cpp $(SOURCE_PATH)user_manager.cpp
libaiml_LDFLAGS = -lxml2
libaiml_INSTALL_PATH = /usr/lib

ADDITIONAL_CFLAGS = -I$(STDUTILS_PATH) -I$(SOURCE_PATH) -I. -DENABLE_PCRECPP=1

include $(THEOS_MAKE_PATH)/library.mk


test: distclean package install

distclean:
	rm *.deb || true
