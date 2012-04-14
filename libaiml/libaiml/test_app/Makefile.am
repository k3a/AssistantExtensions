
METASOURCES = AUTO

SUBDIRS = aiml
AM_CXXFLAGS = -Wall $(WERROR_CXXFLAG) -ansi -pedantic `xml2-config --cflags`

noinst_PROGRAMS = test_app
test_app_SOURCES = main.cpp

test_app_LDADD = $(top_builddir)/src/libaiml.a $(PCRECPP_LIBS) -lstd_utils
test_app_LDFLAGS = $(XML2_LIBS)

