//
//  SiriObjects_private.h
//  AssistantExtensions
//
//  Created by Kexik on 12/29/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
#pragma once

#import <UIKit/UIKit.h>
#import "OS5Additions.h"



// helpers -------------------------------------------------
// Used by some other parts, but should be removed in the future

/** Creates autoreleased NSMutableDictionary representing one custom SA Object.
 \param properties Properties dict. Can be nil, in this case an empty dictionary will be used. */
NSMutableDictionary* SOCreateObjectDict(NSString* group, NSString* className, NSMutableDictionary* properties);

/** Sends a specific AceObject. This object will be the root object instantiated by assistantd. 
 \param ctx Context - can be nil, in this case a new autoreleased basic context will be created. */
NSMutableDictionary* SOCreateAceObjectDict(NSString* refId, NSString* group, NSString* className, NSMutableDictionary* properties);

// commands --------------------------------------------------

/** Sends a RequestCompleted command. This command should be called after the request is fully completed, 
 including all user interactions. */
NSMutableDictionary* SOCreateAceRequestCompleted(NSString* refId);

/** Send a AddViews command used for adding UIViews like UtteranceView or other snippets.
 \param views An array of NSDictionary objects representing view classes. You can create them by calling SOCreateObhectDict.
 \param dialogPhase The phase of dialog, can be "Reflection" - will be replaced by the next command, "Summary" - ?, "Completion" - when done
 */
NSMutableDictionary* SOCreateAceAddViews(NSString* refId, NSArray* views, NSString* dialogPhase=@"Completion", BOOL scrollToTop=NO, BOOL temporary=NO);

/** Send a AddViews command with one view - UtteranceView with specified properties. 
 \param text Text to display.
 \param speakableText Text to speak. If nil, the string specified in text argument will be used.*/
NSMutableDictionary* SOCreateAceAddViewsUtteranceView(NSString* refId, NSString* text, NSString* speakableText=nil, NSString* dialogPhase=@"Completion", BOOL scrollToTop=NO, BOOL temporary=NO);

// objects --------------------------------------------------

/** Creates a AssistantUtteranceView object made from View which will be displayed to the used and text which will be spoken.
 \param text Text to display.
 \param speakableText Text to speak. If nil, the string specified in text argument will be used.*/
NSMutableDictionary* SOCreateAssistantUtteranceView(NSString* text, NSString* speakableText=nil, NSString* dialogIdentifier=@"Misc#ident");


#define AE_VERSION "1.0.4"
