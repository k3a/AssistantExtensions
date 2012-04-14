# This makefile definition is used for my internal purposes.
# You can probably get it working for you as well, but I recommend 
# you to use iOSOpenDev or theos for building extensions.

BUNDLE_NAME=HelloSnippet

SIRI_COMMANDS_ROOT=../..
TOOLCHAIN_ROOT=/ios
TOOLCHAIN_ARCH=i386

CC=$(TOOLCHAIN_ROOT)/usr/bin/llvm-g++-4.2
LD=$(TOOLCHAIN_ROOT)/usr/bin/ld
IBTOOL=/Developer/usr/bin/ibtool
SDK=$(TOOLCHAIN_ROOT)/SDKs/iPhoneOS4.1.sdk
BUNDLE_FULL_NAME=./$(BUNDLE_NAME).assistantExtension

LDFLAGS=-lobjc \
        -framework Foundation \
        -framework UIKit \
        -framework CoreFoundation \
        -multiply_defined suppress \
        -isysroot $(SDK) \
        -L$(TOOLCHAIN_ROOT)/usr/lib \
        -arch armv6 \
        -miphoneos-version-min=2.0 \
        -bundle \
        -Wall \
        -Werror \
        -lobjc \
        -ObjC++ 

CFLAGS= -Os -fobjc-exceptions -fobjc-call-cxx-cdtors -arch armv6 -miphoneos-version-min=2.0 -I$(SIRI_COMMANDS_ROOT) -I$(TOOLCHAIN_ROOT)/usr/include -isysroot $(SDK)


Objects = HelloSnippet.o HelloCommands.o
XibList = $(wildcard src/*.xib)
NibList = $(XibList:.xib=.nib)

Target = $(BUNDLE_FULL_NAME)/$(BUNDLE_NAME)

all:    bundle $(NibList) $(Target)

$(Target): $(Objects)
		$(CC) $(LDFLAGS) -o $@ $^
		$(TOOLCHAIN_ROOT)/usr/bin/i386-ldid -S $(Target)

bundle:
		mkdir -p $(BUNDLE_FULL_NAME)
		cp src/*Info.plist $(BUNDLE_FULL_NAME)/Info.plist
		plutil -convert binary1 $(BUNDLE_FULL_NAME)/Info.plist

%.nib:
		$(IBTOOL) --compile $(BUNDLE_FULL_NAME)/$(notdir $@) $*.xib --sdk $(SDK) 

%.o:    src/%.m*
		$(CC) -c $(CFLAGS) $< -o $@

clean:
		rm -f src/*.o $(Target) $(BUNDLE_FULL_NAME)
		rm -f *.deb
		rm -rf $(BUNDLE_FULL_NAME)

test:	clean all
		ssh ufoxy "rm -rf /Library/AssistantExtensions/$(BUNDLE_FULL_NAME) || true"
		scp -r $(BUNDLE_FULL_NAME) ufoxy:/Library/AssistantExtensions/

test-xcode:	
		ssh ufoxy "rm -rf /Library/AssistantExtensions/$(BUNDLE_FULL_NAME) || true"
		/theos/bin/ldid -S build/Debug-iphoneos/$(BUNDLE_FULL_NAME)/$(BUNDLE_NAME)
		scp -r build/Debug-iphoneos/$(BUNDLE_FULL_NAME) ufoxy:/Library/AssistantExtensions/
		ssh ufoxy "respring"
