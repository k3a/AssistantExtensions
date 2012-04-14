//
//  AESpringBoardMsgCenter.h
//  AssistantExtensions
//
//  Created by Kexik on 11/30/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
#pragma once
#include <Foundation/Foundation.h>
#include <AppSupport/CPDistributedMessagingCenter.h>
#import "SiriObjects.h"

/// Distributed messaging center for SpringBoard process.
@interface AESpringBoardMsgCenter : NSObject
{
    CPDistributedMessagingCenter *center;
    SOLocationData locationData;
    
    NSMutableDictionary* prefs;
}
+(AESpringBoardMsgCenter*)sharedInstance;
-(void)ignoreRestOfRequest:(NSString*)refId;
-(SOLocationData)getLocationData:(NSString*)refId showReflection:(BOOL)show;
-(void)reloadPrefs;
-(id)prefForKey:(NSString*)name;
@end

void SBCenterAssistantDismissed();
