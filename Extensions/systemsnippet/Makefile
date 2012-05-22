include theos/makefiles/common.mk

BUNDLE_NAME = systemsnippet
systemsnippet_BUNDLE_EXTENSION = assistantExtension
systemsnippet_FILES = AEsystemsnippet.mm AEsystemsnippetCommands.mm
systemsnippet_INSTALL_PATH = /Library/AssistantExtensions/
systemsnippet_FRAMEWORKS = UIKit CoreGraphics

include $(THEOS_MAKE_PATH)/bundle.mk

after-install::
	install.exec "killall -9 SpringBoard"
