//
//  AEChatBot.h
//  SiriCommands
//
//  Created by K3A on 2/1/12.
//  Copyright (c) 2012 K3A. All rights reserved.
//

#import <Foundation/Foundation.h>

bool InChatMode();
void StartChatMode(NSString* refId);
bool HandleChat(NSString* refId, NSString* text, NSArray* tokens, NSSet* tokenset);