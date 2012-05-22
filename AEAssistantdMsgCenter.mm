//
//  AEAssistantdMsgCenter.mm
//  AssistantExtensions
//
//  Created by Kexik on 01/08/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AEAssistantdMsgCenter.h"
#include "main.h"
#include "AESupport.h"
#include <objc/runtime.h>


@implementation AEAssistantdMsgCenter

AEAssistantdMsgCenter* s_ad_inst = nil;

+(AEAssistantdMsgCenter*)sharedInstance
{
    return s_ad_inst;
}

static NSDictionary* LocationDict(CLLocation* loc)
{
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    [dict setObject:[NSNumber numberWithFloat:loc.coordinate.latitude] forKey:@"latitude"];
    [dict setObject:[NSNumber numberWithFloat:loc.coordinate.longitude] forKey:@"longitude"];
    [dict setObject:[NSNumber numberWithFloat:loc.altitude] forKey:@"altitude"];
    [dict setObject:[NSNumber numberWithFloat:loc.horizontalAccuracy] forKey:@"horizontalAccuracy"];
    [dict setObject:[NSNumber numberWithFloat:loc.verticalAccuracy] forKey:@"verticalAccuracy"];
    [dict setObject:[NSNumber numberWithFloat:loc.speed] forKey:@"speed"];
    [dict setObject:[NSNumber numberWithFloat:loc.course] forKey:@"direction"];
    [dict setObject:[NSNumber numberWithUnsignedLong:[loc.timestamp timeIntervalSince1970]] forKey:@"timestamp"];
    
    return dict;
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    if (newLocation.horizontalAccuracy < 150)
    {
        NSLog(@"AE: Got location.");
        gotLocation = YES;
        [recentLocation autorelease];
        recentLocation = [LocationDict(newLocation) retain];;
        
        [locationManager stopUpdatingLocation];
        NSDictionary* arg = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES],@"result",recentLocation,@"location", nil];
        IPCCall(@"me.k3a.AssistantExtensions", @"GotLocation", arg);
    }
}

- (NSDictionary*)handleSend2Client:(NSString *)name userInfo:(NSDictionary *)userInfo 
{
    BOOL success = NO;
    if (SessionSendToClient([userInfo objectForKey:@"object"], nil)) success = YES;
    
    return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:success],@"reply", nil];
}

- (NSDictionary*)handleSend2Server:(NSString *)name userInfo:(NSDictionary *)userInfo 
{
    BOOL success = NO;
    if (SessionSendToServer([userInfo objectForKey:@"object"], nil)) success = YES;
    
    return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:success],@"reply", nil];
}

- (NSDictionary*)handleGetLocation:(NSString *)name userInfo:(NSDictionary *)userInfo 
{
    if (![CLLocationManager locationServicesEnabled])
    {
        return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO],@"result", nil];
    }
    else
    {
        unsigned long nowTimestamp = [[NSDate date] timeIntervalSince1970];
        
        if (recentLocation && (nowTimestamp - [[recentLocation objectForKey:@"timestamp"] unsignedLongValue]) < 60)
        {
            NSLog(@"AE: Using cached location data.");
            NSDictionary* arg = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithBool:YES],@"result",recentLocation,@"location", nil];
            IPCCall(@"me.k3a.AssistantExtensions", @"GotLocation", arg);
        }
        else
        {
            NSLog(@"AE: Getting location...");
            gotLocation = NO;
            [locationManager startUpdatingLocation];
        }
    }
    return nil;
}

-(NSDictionary*)handleSay:(NSString*)name userInfo:(NSDictionary*)userInfo
{
    AESay([userInfo objectForKey:@"text"], [userInfo objectForKey:@"leng"]);
	return nil;
}

- (id)init {
	if((self = [super init])) {
        NSLog(@"************* AssistantExtensions AD MsgCenter Startup *************");
        
        s_ad_inst = self;
        
        // init center
		center = [[CPDistributedMessagingCenter centerNamed:@"me.k3a.AssistantExtensions.ad"] retain];
		[center runServerOnCurrentThread];
        [center registerForMessageName:@"Send2Client" target:self selector:@selector(handleSend2Client:userInfo:)];
        [center registerForMessageName:@"Send2Server" target:self selector:@selector(handleSend2Server:userInfo:)];
        [center registerForMessageName:@"GetLocation" target:self selector:@selector(handleGetLocation:userInfo:)];
        [center registerForMessageName:@"Say"         target:self selector:@selector(handleSay:userInfo:)];
        
        // init location manager
        locationManager = [[CLLocationManager alloc] initWithEffectiveBundle:[NSBundle mainBundle]];
        locationManager.delegate = self;
        locationManager.distanceFilter = kCLDistanceFilterNone; // whenever we move
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters; // 100 m
        switch([CLLocationManager authorizationStatus])
        {
            case kCLAuthorizationStatusNotDetermined: NSLog(@"AE: CL auth status undetermined"); break;
            case kCLAuthorizationStatusRestricted: NSLog(@"AE: CL auth status restricted"); break;
            case kCLAuthorizationStatusDenied: NSLog(@"AE: CL auth status denied"); break;
            default: break;
        }
	}
    
	return self;
}

- (void)dealloc {
    [locationManager release];
	[center release];
	[super dealloc];
}

@end
