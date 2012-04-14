include theos/makefiles/common.mk

BUNDLE_NAME = LocationTest
LocationTest_BUNDLE_EXTENSION = assistantExtension
LocationTest_FILES = AELocationTest.mm AELocationTestCommands.mm
LocationTest_INSTALL_PATH = /Library/AssistantExtensions/
LocationTest_FRAMEWORKS = UIKit CoreGraphics

include $(THEOS_MAKE_PATH)/bundle.mk

after-install::
	install.exec "killall -9 SpringBoard"

test: distclean package install

distclean:
	rm *.deb || true
