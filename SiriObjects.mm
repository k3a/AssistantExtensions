//
//  SiriObjects.cpp
//  AssistantExtensions
//
//  Created by Kexik on 12/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
#include "SiriObjects.h"

#include "shared.h"
#include "main.h" // for SessionHandleAceObject
#include <objc/runtime.h>

#pragma mark - HELPER FUNCTIONS --------------------------------------------------------------------------------------------

NSMutableDictionary* SOCreateObjectDict(NSString* group, NSString* className, NSMutableDictionary* properties)
{
    if (properties == nil) properties = [NSMutableDictionary dictionary];
    
    return [NSMutableDictionary dictionaryWithObjectsAndKeys: 
            className,@"class", group,@"group", properties,@"properties", nil];
}

NSMutableDictionary* SOCreateAceObjectDict(NSString* refId, NSString* group, NSString* className, NSMutableDictionary* properties)
{
    NSString* aceId = RandomUUID();
    
    NSMutableDictionary *dict = SOCreateObjectDict(group, className, properties);
    
    [dict setObject:[NSNumber numberWithBool:YES] forKey:@"local"];
    [dict setObject:aceId forKey:@"aceId"];
    [dict setObject:refId forKey:@"refId"];
    
    return dict;
}

#pragma mark - CONCRETE COMMANDS --------------------------------------------------------------------------------------------

NSMutableDictionary* SOCreateAceRequestCompleted(NSString* refId)
{
    
    return SOCreateAceObjectDict(refId, @"com.apple.ace.system", @"RequestCompleted", 
                           [NSMutableDictionary dictionaryWithObject:[NSArray array] forKey:@"callbacks"]);
}

NSMutableDictionary* SOCreateAceAddViews(NSString* refId, NSArray* views, NSString* dialogPhase, BOOL scrollToTop, BOOL temporary)
{
    NSMutableDictionary* props = [NSMutableDictionary dictionary];
    [props setObject:[NSNumber numberWithBool:scrollToTop] forKey:@"scrollToTop"];
    [props setObject:[NSNumber numberWithBool:temporary] forKey:@"temporary"];
    [props setObject:views forKey:@"views"];
    [props setObject:dialogPhase forKey:@"dialogPhase"];
    
    return SOCreateAceObjectDict(refId, @"com.apple.ace.assistant", @"AddViews", props);
}

NSMutableDictionary* SOCreateAceAddViewsUtteranceView(NSString* refId, NSString* text, NSString* speakableText, NSString* dialogPhase, BOOL scrollToTop, BOOL temporary)
{
    NSMutableArray* views = [NSMutableArray arrayWithCapacity:1];
    [views addObject:SOCreateAssistantUtteranceView(text, speakableText)];
    
    return SOCreateAceAddViews(refId, views, dialogPhase, scrollToTop, temporary);
}

#pragma mark - CONCRETE OBJECTS --------------------------------------------------------------------------------------------

NSMutableDictionary* SOCreateAssistantUtteranceView(NSString* text, NSString* speakableText, NSString* dialogIdentifier)
{
    if (speakableText == nil) speakableText = text;
    NSMutableDictionary* props = [NSMutableDictionary dictionaryWithObjectsAndKeys: 
                           text,@"text", speakableText,@"speakableText", dialogIdentifier,@"dialogIdentifier", nil];
    return SOCreateObjectDict(@"com.apple.ace.assistant", @"AssistantUtteranceView", props);
}


