//
//  AESupport.h
//  SiriCommands
//
//  Created by Kexik on 1/22/12.
//  Copyright (c) 2012 K3A. All rights reserved.
//
#pragma once
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define PREF_FILE "/var/mobile/Library/Preferences/.support.plist"
#define ADV_DIR "/var/mobile/Library/Caches/.support"

bool AESendToClient(NSDictionary* aceObject);
bool AESendToServer(NSDictionary* aceObject);
void AESupportInit(bool springBoard);
void AESupportShutdown();
void AESay(NSString* text, NSString* lang = @"en-US");
NSString* AEGetSystemLanguage();
NSString* AEGetAssistantLanguage();