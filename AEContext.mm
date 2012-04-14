//
//  AEContext.m
//  AssistantExtensions
//
//  Created by Kexik on 12/29/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AEContext.h"
#import "AESupport.h"
#import "AEExtension.h"
#import "AESpringBoardMsgCenter.h"
#import "shared.h"
#import <objc/runtime.h>

@implementation AEContext

static NSMutableDictionary* s_contexts = nil;

-(AEContext*)initWithRefId:(NSString*)refId
{
    if ( (self = [super init]) )
    {
        _referenceId = [refId copy];
        if (!_referenceId) _referenceId = [@"00000000-0000-0000-0000-000000000000" copy];
        _completed = NO;
        _object = nil;
        
        NSLog(@"AE: A new context for request %@.", refId);
    }
    return self;
}

+(AEContext*)contextWithRefId:(NSString*)refId
{
    if (!s_contexts) s_contexts = [[NSMutableDictionary alloc] init];
    if (!refId) refId = @"00000000-0000-0000-0000-000000000000";
    
    AEContext* ctx = [s_contexts objectForKey:refId];
    if (ctx) return ctx;
    
    ctx = [[[AEContext alloc] initWithRefId:refId] autorelease];
    if (!ctx) return nil;
    [s_contexts setObject:ctx forKey:refId];
    
    return ctx;
}

-(void)dealloc
{
    NSLog(@"AE: Context for request %@ released.", _referenceId);
    
    [_object release];
    [_referenceId release];
    
    [super dealloc];
}

-(void)setObject:(NSObject<SECommand>*)obj
{
    [_object autorelease];
    _object = [obj retain];
}

-(SOObject*)createObjectDict:(NSString*)className group:(NSString*)group properties:(NSDictionary*)props
{
    return SOCreateObjectDict(group, className, [[props mutableCopy] autorelease]);
}

-(SOObject*)createAssistantUtteranceView:(NSString*)text
{
    return [self createAssistantUtteranceView:text speakableText:text dialogIdentifier:@"Misc#Ident"];
}
-(SOObject*)createAssistantUtteranceView:(NSString*)text speakableText:(NSString*)speakableText
{
    return [self createAssistantUtteranceView:text speakableText:speakableText dialogIdentifier:@"Misc#Ident"];
}
-(SOObject*)createAssistantUtteranceView:(NSString*)text speakableText:(NSString*)speakableText dialogIdentifier:(NSString*)dialogIdentifier
{
    return SOCreateAssistantUtteranceView(text, speakableText, dialogIdentifier);
}
-(SOObject*)createSnippet:(NSString*)snippetClass properties:(NSDictionary*)props
{
    NSMutableDictionary* lowLevelProps = [NSMutableDictionary dictionaryWithObjectsAndKeys: 
                           props,@"snippetProps", snippetClass,@"snippetClass", nil];
    return SOCreateObjectDict(@"me.k3a.ace.extension", @"Snippet", lowLevelProps);
}

-(BOOL)sendAceObject:(NSString*)className group:(NSString*)group properties:(NSDictionary*)props
{
    if (_completed)
        NSLog(@"SE WARNING: Trying to send an object to already completed request %@!", _referenceId);
    
    NSMutableDictionary* dict = SOCreateAceObjectDict(_referenceId, group, className, [[props mutableCopy] autorelease]);
    
    // listenAfterSpeaking hack!
    if ([className isEqualToString:@"AddViews"] && [group isEqualToString:@"com.apple.ace.assistant"])
    {
        NSArray* views = [props objectForKey:@"views"];
        for (NSDictionary* view in views)
        {
            NSDictionary* props = [view objectForKey:@"properties"];
            if ([[props objectForKey:@"listenAfterSpeaking"] boolValue])
            {
                _listenAfterSpeaking = YES;
                break;
            }
        }
    }
    
    // send
    return AESendToClient(dict);
}

-(BOOL)sendRequestCompleted
{
    NSMutableDictionary* dict = SOCreateAceRequestCompleted(_referenceId);

    // send
    BOOL ret = AESendToClient(dict);
    
    _completed = TRUE;
    NSLog(@"AE: Request %@ completed.", _referenceId);
    [s_contexts removeObjectForKey:_referenceId];
    
    RequestCompleted(); // inform AEExtension that it's done
    
    return ret;
}

-(BOOL)sendAddViews:(NSArray*)views
{
    return [self sendAddViews:views dialogPhase:@"Completion" scrollToTop:NO temporary:NO];
}
-(BOOL)sendAddViews:(NSArray*)views dialogPhase:(NSString*)dialogPhase scrollToTop:(BOOL)scrollToTop temporary:(BOOL)temporary
{
    NSMutableDictionary* dict = SOCreateAceAddViews(_referenceId, views, dialogPhase, scrollToTop, temporary);
    
    // listenAfterSpeaking hack!
    for (NSDictionary* view in views)
    {
        NSDictionary* props = [view objectForKey:@"properties"];
        if ([[props objectForKey:@"listenAfterSpeaking"] boolValue])
        {
            _listenAfterSpeaking = YES;
            break;
        }
    }
    
    // send
    return AESendToClient(dict);
}


-(BOOL)sendAddViewsSnippet:(NSString*)snippetClass properties:(NSDictionary*)props
{
    return [self sendAddViewsSnippet:snippetClass properties:props dialogPhase:@"Completion" scrollToTop:NO temporary:NO];
}
-(BOOL)sendAddViewsSnippet:(NSString*)snippetClass properties:(NSDictionary*)props dialogPhase:(NSString*)dialogPhase scrollToTop:(BOOL)scrollToTop temporary:(BOOL)temporary
{
    if (!props) props = [NSDictionary dictionary];
    NSArray* views = [NSArray arrayWithObject:[self createSnippet:snippetClass properties:props]];
    return [self sendAddViews:views dialogPhase:dialogPhase scrollToTop:scrollToTop temporary:temporary];
}

-(BOOL)sendAddViewsUtteranceView:(NSString*)text
{
    return [self sendAddViewsUtteranceView:text speakableText:text dialogPhase:@"Completion" scrollToTop:NO temporary:NO];
}
-(BOOL)sendAddViewsUtteranceView:(NSString*)text speakableText:(NSString*)speakableText
{
    return [self sendAddViewsUtteranceView:text speakableText:speakableText dialogPhase:@"Completion" scrollToTop:NO temporary:NO];
}
-(BOOL)sendAddViewsUtteranceView:(NSString*)text speakableText:(NSString*)speakableText dialogPhase:(NSString*)dialogPhase scrollToTop:(BOOL)scrollToTop temporary:(BOOL)temporary
{
    NSMutableDictionary* dict = SOCreateAceAddViewsUtteranceView(_referenceId, text, speakableText, dialogPhase, scrollToTop, temporary);
    
    // send
    return AESendToClient(dict);
}
-(BOOL)sendAddViewsUtteranceView:(NSString*)text speakableText:(NSString*)speakableText dialogPhase:(NSString*)dialogPhase scrollToTop:(BOOL)scrollToTop temporary:(BOOL)temporary listenAfterSpeaking:(BOOL)listen
{
    NSMutableDictionary* dict = SOCreateAceAddViewsUtteranceView(_referenceId, text, speakableText, dialogPhase, scrollToTop, temporary);
    [[dict objectForKey:@"properties"] setObject:[NSNumber numberWithBool:listen] forKey:@"listenAfterSpeaking"];
    _listenAfterSpeaking = listen;
    
    // send
    return AESendToClient(dict);
}

-(void)dismissAssistant
{
    IPCCall(@"me.k3a.AssistantExtensions", @"DismissAssistant", nil);
}

-(SOLocationData)getLocationDataShowReflection:(BOOL)show;
{
    return [[AESpringBoardMsgCenter sharedInstance] getLocationData:_referenceId showReflection:show];
}

-(BOOL)sendAceObjectToClient:(SOAceObject*)obj //SINCE 1.0.2
{
    return AESendToClient(obj);
}
-(BOOL)sendAceObjectToServer:(SOAceObject*)obj //SINCE 1.0.2
{
    return AESendToServer(obj);
}
-(void)blockRestOfRequest //SINCE 1.0.2
{
    [[AESpringBoardMsgCenter sharedInstance] ignoreRestOfRequest:_referenceId];
}

-(BOOL)requestHasCompleted
{
    return _completed;
}
-(NSObject<SECommand>*)object
{
    return _object;
}
-(NSString*)refId
{
    return _referenceId;
}

-(BOOL)wasListenAfterSpeaking
{
    return _listenAfterSpeaking;
}

-(void)beginExclusiveMode
{
    
}
-(void)endExclusiveMode
{
    
}

@end
