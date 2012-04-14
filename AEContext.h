//
//  AEContext.h
//  AssistantExtensions
//
//  Created by Kexik on 12/29/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SiriObjects.h"

/// Context of one assistant request/response. Used also for creating and sending Siri objects.
@interface AEContext : NSObject <SEContext> {
    NSString* _referenceId;
    
    BOOL _completed;
    NSObject<SECommand>* _object;
    BOOL _listenAfterSpeaking;
}

+(AEContext*)contextWithRefId:(NSString*)refId;
-(void)setObject:(NSObject<SECommand>*)obj;

-(SOObject*)createObjectDict:(NSString*)className group:(NSString*)group properties:(NSDictionary*)props;
-(SOObject*)createAssistantUtteranceView:(NSString*)text speakableText:(NSString*)speakableText;
-(SOObject*)createAssistantUtteranceView:(NSString*)text speakableText:(NSString*)speakableText dialogIdentifier:(NSString*)dialogIdentifier;
-(SOObject*)createSnippet:(NSString*)snippetClass properties:(NSDictionary*)props;

-(BOOL)sendAceObject:(NSString*)className group:(NSString*)group properties:(NSDictionary*)props;

-(BOOL)sendRequestCompleted;

-(BOOL)sendAddViews:(NSArray*)views;
-(BOOL)sendAddViews:(NSArray*)views dialogPhase:(NSString*)dialogPhase scrollToTop:(BOOL)scrollToTop temporary:(BOOL)temporary;

-(BOOL)sendAddViewsSnippet:(NSString*)snippetClass properties:(NSDictionary*)props;
-(BOOL)sendAddViewsSnippet:(NSString*)snippetClass properties:(NSDictionary*)props dialogPhase:(NSString*)dialogPhase scrollToTop:(BOOL)scrollToTop temporary:(BOOL)temporary;

-(BOOL)sendAddViewsUtteranceView:(NSString*)text;
-(BOOL)sendAddViewsUtteranceView:(NSString*)text speakableText:(NSString*)speakableText;
-(BOOL)sendAddViewsUtteranceView:(NSString*)text speakableText:(NSString*)speakableText dialogPhase:(NSString*)dialogPhase scrollToTop:(BOOL)scrollToTop temporary:(BOOL)temporary;
-(BOOL)sendAddViewsUtteranceView:(NSString*)text speakableText:(NSString*)speakableText dialogPhase:(NSString*)dialogPhase scrollToTop:(BOOL)scrollToTop temporary:(BOOL)temporary listenAfterSpeaking:(BOOL)listen;

-(SOLocationData)getLocationDataShowReflection:(BOOL)show;
-(BOOL)sendAceObjectToClient:(SOAceObject*)obj; //SINCE 1.0.2
-(BOOL)sendAceObjectToServer:(SOAceObject*)obj; //SINCE 1.0.2
-(void)blockRestOfRequest; //SINCE 1.0.2

-(BOOL)requestHasCompleted;
-(NSObject<SECommand>*)object;
-(NSString*)refId;

// private:
-(BOOL)wasListenAfterSpeaking;

@end
