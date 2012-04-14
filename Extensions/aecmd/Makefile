include theos/makefiles/common.mk

TOOL_NAME = AECmd
AECmd_FILES = main.mm
AECmd_PRIVATE_FRAMEWORKS = AppSupport

include $(THEOS_MAKE_PATH)/tool.mk

test: all
	ssh ufoxy "rm AECmd"
	scp obj/AECmd ufoxy:
