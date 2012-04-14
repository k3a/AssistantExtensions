//
//  systemcmds.h
//  objcdump
//
//  Created by Kexik on 11/29/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
#pragma once

#import <Foundation/Foundation.h> 

bool InitSystemCmds();
void ShutdownSystemCmds();
bool HandleSpeechSystemCmds(NSString* refId, NSString* text, NSArray* tokens, NSSet* tokenset);
