//
//  AEAssistantdMsgCenter.h
//  AssistantExtensions
//
//  Created by Kexik on 01/08/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
#pragma once
#import <Foundation/Foundation.h>
#import <AppSupport/CPDistributedMessagingCenter.h>
#import <CoreLocation/CoreLocation.h>

/// Distributed messaging center for assistantd process.
@interface AEAssistantdMsgCenter : NSObject <CLLocationManagerDelegate>
{
    CPDistributedMessagingCenter *center;
    CLLocationManager *locationManager;
    NSDictionary* recentLocation;
    BOOL           gotLocation;
}
+(AEAssistantdMsgCenter*)sharedInstance;
@end
