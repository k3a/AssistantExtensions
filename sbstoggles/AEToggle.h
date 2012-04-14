//
//  AEToggle.h
//  AssistantExtensions
//
//  Created by K3A on 11/29/11.
//  Copyright (c) 2011 K3A. All rights reserved.
//
#pragma once

#import <Foundation/Foundation.h> 

typedef bool (*BoolFn)();
typedef bool (*VoidBoolFn)(bool b);

/// Class representing one SBSettings toggle, offers functionality like turning on/off or gettings state.
@interface AEToggle : NSObject {
@private
    BoolFn _isEnabled;
    BoolFn _getStateFast;
    BoolFn _isCapable;
    VoidBoolFn _setState;
    void* _dylib;
    
    NSString* _speakableName;
}

+(id)findToggleNamed:(NSString*)name; // uses similarity matching
+(BOOL)initToggles;
+(void)shutdownToggles;
+(NSArray*)allToggleNames;

+(id)toggleWithName:(NSString*)name;

-(id)initWithName:(NSString*)name;
-(BOOL)state;
-(BOOL)isCapable;
-(void)setState:(BOOL)state;
-(NSString*)speakableName;

@end