include theos/makefiles/common.mk

SUBPROJECTS = aecustomizerpreferences

BUNDLE_NAME = Customizer
Customizer_BUNDLE_EXTENSION = assistantExtension
Customizer_FILES = AECustomizer.mm AECustomizerCommands.mm
Customizer_INSTALL_PATH = /Library/AssistantExtensions/
Customizer_FRAMEWORKS = UIKit CoreGraphics

include $(THEOS_MAKE_PATH)/bundle.mk
include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "killall -9 SpringBoard"

test: distclean package install

distclean:
	rm *.deb || true
