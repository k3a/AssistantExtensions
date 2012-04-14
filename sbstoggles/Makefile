include theos/makefiles/common.mk

BUNDLE_NAME = SBSToggles
SBSToggles_BUNDLE_EXTENSION = assistantExtension
SBSToggles_FILES = AEToggle.mm AESBSToggles.mm AESBSTogglesCommands.mm
SBSToggles_INSTALL_PATH = /Library/AssistantExtensions/
SBSToggles_FRAMEWORKS = UIKit CoreGraphics

include $(THEOS_MAKE_PATH)/bundle.mk

after-install::
	install.exec "killall -9 SpringBoard"
