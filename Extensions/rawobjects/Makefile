include theos/makefiles/common.mk

BUNDLE_NAME = RawObjects
RawObjects_BUNDLE_EXTENSION = assistantExtension
RawObjects_FILES = AERawObjects.mm
RawObjects_INSTALL_PATH = /Library/AssistantExtensions/
RawObjects_FRAMEWORKS = UIKit CoreGraphics

include $(THEOS_MAKE_PATH)/bundle.mk

after-install::
	install.exec "killall -9 SpringBoard"
