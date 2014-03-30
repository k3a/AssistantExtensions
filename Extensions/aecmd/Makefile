include theos/makefiles/common.mk

TOOL_NAME = AECmd
AECmd_FILES = main.mm
AECmd_PRIVATE_FRAMEWORKS = AppSupport

include $(THEOS_MAKE_PATH)/tool.mk

export TARGET=iphone:latest:5.0
export ARCHS = armv7
TARGET_CC = xcrun --sdk iphoneos clang
TARGET_CXX = xcrun --sdk iphoneos clang++

test: all
	ssh ufoxy "rm AECmd"
	scp obj/AECmd ufoxy:
