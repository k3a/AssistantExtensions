include theos/makefiles/common.mk

SUBPROJECTS = AEPrefs customizer standard jpsupport

TWEAK_NAME = AssistantExtensions
AssistantExtensions_FILES = AEDevHelper.xm AEAssistantdMsgCenter.mm AEChatBot.mm AEContext.mm AEExtension.mm AESpringBoardMsgCenter.mm AEStringAdditions.mm AESupport.mm AEToggle.mm SiriObjects.mm AEX.mm
AssistantExtensions_FILES += main.mm shared.mm systemcmds.mm
AssistantExtensions_FRAMEWORKS = Foundation UIKit CoreFoundation Accounts Twitter CoreLocation
AssistantExtensions_PRIVATE_FRAMEWORKS = AppSupport GraphicsServices AssistantUI SAObjects VoiceServices BulletinBoard AssistantServices
AssistantExtensions_LDFLAGS  = -multiply_defined suppress -Llib -Fframeworks -dynamiclib -init _Initialize
#AssistantExtensions_LDFLAGS += -Xlinker -x -Xlinker -exported_symbol -Xlinker _Initialize
AssistantExtensions_LDFLAGS += -ObjC++ -fobjc-exceptions -fobjc-call-cxx-cdtors
AssistantExtensions_LDFLAGS += -lobjc -lsubstrate -lpthread -laiml -lpcre
AssistantExtensions_CFLAGS = -Os -funroll-loops -g -DSC_PRIVATE -fobjc-abi-version=2 -fno-exceptions -fobjc-exceptions -fobjc-call-cxx-cdtors -Iinclude

include $(THEOS_MAKE_PATH)/tweak.mk
include $(FW_MAKEDIR)/aggregate.mk

before-package:: $(THEOS_PACKAGE_DIR) copy-layout

copy-layout:
	$(ECHO_NOTHING)mkdir -p "$(THEOS_STAGING_DIR)/DEBIAN"$(ECHO_END)
	$(ECHO_NOTHING)cp layout/DEBIAN/postinst "$(THEOS_STAGING_DIR)/DEBIAN"$(ECHO_END)
	$(ECHO_NOTHING)rsync -a --exclude=.svn layout/Library "$(THEOS_STAGING_DIR)/"$(ECHO_END)
	$(ECHO_NOTHING)rsync -a --exclude=.svn layout/System "$(THEOS_STAGING_DIR)/"$(ECHO_END)
	$(ECHO_NOTHING)mkdir -p "$(THEOS_STAGING_DIR)/usr/include"$(ECHO_END)
	$(ECHO_NOTHING)cp SiriObjects.h "$(THEOS_STAGING_DIR)/usr/include/"$(ECHO_END)

distclean:
	rm -rf *.deb | true

test: distclean package install
