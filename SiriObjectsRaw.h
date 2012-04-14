//
//  SiriObjects.h
//  AssistantExtensions
//
//  Created by Kexik on 12/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
#pragma once
#include <Foundation/Foundation.h>

/// Type representing one Siri class description as NSMutableDictionary
typedef NSMutableDictionary SOObject;

#ifdef SC_PRIVATE
# import "SiriObjects_private.h"
# define SC_SUPER(cls) cls
#else
# define SC_SUPER(cls) NSObject
#endif

/// Type representing a concrete SiriObject
@protocol SOAceObject <NSObject>
@required
/// Class name beginning with SA, e.g. SATest
- (id)encodedClassName;
/// Group identifier, e.g. com.company.ace
- (id)groupIdentifier;
@end

/// Any object (NSMutableDictionary)
typedef NSMutableDictionary SOObject;
/// Root object (NSMutableDictionary)
typedef SOObject SOAceObject; 


@protocol SOSystem <NSObject>
@required
-(BOOL)registerAcronym:(NSString*)acronym group:(NSString*)group;
@end

/// Protocol specifying methods of context passed via handleSpeech
@protocol SOContext <NSObject>
@required
-(SOObject*)createObjectDict:(NSString*)className group:(NSString*)group properties:(NSDictionary*)props;
-(SOObject*)createAssistantUtteranceView:(NSString*)text;
-(SOObject*)createAssistantUtteranceView:(NSString*)text speakableText:(NSString*)speakableText;
-(SOObject*)createAssistantUtteranceView:(NSString*)text speakableText:(NSString*)speakableText dialogIdentifier:(NSString*)dialogIdentifier;

-(SOAceObject*)sendAceObject:(NSString*)className group:(NSString*)group properties:(NSDictionary*)props;

-(SOAceObject*)sendRequestCompleted;

-(SOAceObject*)sendAddViews:(NSArray*)views;
-(SOAceObject*)sendAddViews:(NSArray*)views dialogPhase:(NSString*)dialogPhase scrollToTop:(BOOL)scrollToTop temporary:(BOOL)temporary;

-(SOAceObject*)sendAddViewsUtteranceView:(NSString*)text;
-(SOAceObject*)sendAddViewsUtteranceView:(NSString*)text speakableText:(NSString*)speakableText;
-(SOAceObject*)sendAddViewsUtteranceView:(NSString*)text speakableText:(NSString*)speakableText dialogPhase:(NSString*)dialogPhase scrollToTop:(BOOL)scrollToTop temporary:(BOOL)temporary;

@end


/// Protocol specifying methods of the extension's principal class
@protocol SOExtension <NSObject>

@required
-(id)initWithSystem:(id<SOSystem>)system;

@optional
-(BOOL)handleSpeech:(NSString*)text tokens:(NSArray*)tokens tokenSet:(NSSet*)tokenset context:(id<SOContext>)ctx;

@end

