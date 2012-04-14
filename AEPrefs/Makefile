include theos/makefiles/common.mk

BUNDLE_NAME = AEPrefs
AEPrefs_FILES = AEPrefs.mm AEDonate.mm AEExtensionCell.mm
AEPrefs_INSTALL_PATH = /Library/PreferenceBundles
AEPrefs_FRAMEWORKS = UIKit Accounts Twitter
AEPrefs_PRIVATE_FRAMEWORKS = Preferences AppSupport

include $(THEOS_MAKE_PATH)/bundle.mk

IBTOOL=/Developer/usr/bin/ibtool
XibList = $(wildcard *.xib)
NibList = $(XibList:.xib=.nib)

after-all:: $(NibList)

internal-stage:: 
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/AEPrefs.plist$(ECHO_END)

%.nib:
	$(IBTOOL) --compile Resources/$(notdir $@) $*.xib

test: all stage
	ssh root@ufoxy "rm -rf /Library/PreferenceBundles/AEPrefs.bundle ; killall Preferences || true"
	scp -r $(THEOS_STAGING_DIR)/* root@ufoxy:/
	ssh root@ufoxy "sbopenurl 'prefs:root=AssistantExtensions'"
