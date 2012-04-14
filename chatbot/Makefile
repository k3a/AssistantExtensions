include theos/makefiles/common.mk

BUNDLE_NAME = ChatBot
ChatBot_BUNDLE_EXTENSION = assistantExtension
ChatBot_FILES = AEChatBot.mm AEChatBotCommands.mm
ChatBot_INSTALL_PATH = /Library/AssistantExtensions/
ChatBot_FRAMEWORKS = UIKit CoreGraphics
ChatBot_CFLAGS = -I../include/
ChatBot_LDFLAGS = -L../lib/ -laiml

include $(THEOS_MAKE_PATH)/bundle.mk

after-install::
	install.exec "killall -9 SpringBoard"
