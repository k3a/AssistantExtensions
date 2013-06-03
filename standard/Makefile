GO_EASY_ON_ME = 1

include theos/makefiles/common.mk

BUNDLE_NAME = Standard
Standard_BUNDLE_EXTENSION = assistantExtension
Standard_FILES = AEStandardCommands.mm AEStandard.mm AERandomSnippet.m
Standard_INSTALL_PATH = /Library/AssistantExtensions/

Standard_CFLAGS = -I../include
Standard_LDFLAGS = -L../lib -ldisplay
Standard_FRAMEWORKS = UIKit CoreGraphics Twitter Accounts

include $(THEOS_MAKE_PATH)/bundle.mk

after-install::
	install.exec "killall -9 SpringBoard"
