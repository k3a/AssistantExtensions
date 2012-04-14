//
//  AEExtension.h
//  AssistantExtensions
//
//  Created by Kexik on 12/26/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
#pragma once
#import <Foundation/Foundation.h>
#import "SiriObjects.h"
#import "SiriObjects_private.h"
#import "AEContext.h"
#import "AEX.h"

/// A class represention one AE extension with some static methods for common tasks with extension registry
@interface AEExtension : NSObject<SESystem>  {
@private
    BOOL _initialized;
    id<SEExtension> _principal;
    NSBundle* _bundle;
    NSString* _name;
    NSString* _displayName;
    NSString* _author;
    NSString* _web;
    NSString* _version;
    NSString* _desc;
    NSString* _ident;
    BOOL _hasPreferences;
    NSString* _preferenceBundle;
    
    NSMutableArray* _commands; // array of NSObject<SECommand>*
    NSMutableArray* _snippets; // array of NSString class names
    
    BOOL _respondsToServerToClient; // handles that method
    BOOL _respondsToClientToServer; // handles that method
    NSSet* _serverToClientFilter;
    NSSet* _clientToServerFilter;
    
    NSString* _currLang;
    NSString* _currLangDir;
    NSDictionary* _currLangDict;
    
    NSObject<SECommand>* _nextCommand; // if this extension requested "listen after speaking", here is the command instance which needs to be called after the speech is recognized next time.
    AEPattern* _nextPattern; // the same as _nextCommand but stores the pattern in which "listen after speaking" was requested
    
    NSMutableArray* _patterns;
    id<SECommand> _commandForCurrentPatternRegistrations; // an instance of SECommand for which user will call registerPattern* methods
    NSDictionary* _patternsPlist; // dictionary holding Patterns.plist
}

+(id)findExtensionNamed:(NSString*)name;
+(BOOL)initExtensions;
+(void)reloadExtensions;
+(void)shutdownExtensions;
+(void)switchToLanguage:(NSString*)lang;
+(NSArray*)allExtensionsNames;
+(NSArray*)allExtensions;

+(id)extensionWithName:(NSString*)name;

-(id)initWithName:(NSString*)name;
-(NSString*)name;
-(NSString*)displayName;
-(NSString*)author;
-(NSString*)website;
-(NSString*)description;
-(NSString*)version;
-(BOOL)hasPreferenceBundle;
-(NSString*)preferenceBundle;
-(BOOL)enabled;
-(NSString*)iconPath;
-(NSString*)identifier;
-(NSString*)pathToInfoDictionary;
//-(id<SOExtension>)principalObject;
-(NSObject<SECommand>*)handleSpeech:(NSString*)text tokens:(NSArray*)tokens tokenSet:(NSSet*)tokenset context:(AEContext*)ctx;
-(NSObject<SESnippet>*)allocSnippet:(NSString*)snippetClass properties:(NSDictionary *)props; // can return nil
-(BOOL)handlesServerToClientClass:(NSString*)className;
-(BOOL)handlesClientToServerClass:(NSString*)className;
-(NSDictionary*)serverToClient:(NSDictionary*)input context:(AEContext*)ctx;
-(NSDictionary*)clientToServer:(NSDictionary*)input context:(AEContext*)ctx;
-(void)callAssistantDismissed;
-(void)callAssistantActivated;
-(void)languageChangedTo:(NSString*)lang;

// public methods (SESystem) --------------------------------------------------
-(BOOL)setServerToClientFilter:(NSArray*)allowedClasses;
-(BOOL)setClientToServerFilter:(NSArray*)allowedClasses;
-(BOOL)registerCommand:(Class)cls;
-(BOOL)registerSnippet:(Class)cls;
-(NSString*)systemVersion;
-(NSString*)localizedString:(NSString*)text; //SINCE 1.0.2
-(NSString*)localizedString:(NSString*)text inLanguage:(NSString*)lang; //SINCE 1.0.2
-(BOOL)registerPattern:(NSString*)pattern target:(id)target selector:(SEL)sel userInfo:(id)user; //SINCE 1.0.2
-(BOOL)registerPattern:(NSString*)pattern target:(id)target selector:(SEL)sel; //SINCE 1.0.2
-(BOOL)registerPattern:(NSString*)pattern selector:(SEL)sel userInfo:(id)user; //SINCE 1.0.2
-(BOOL)registerPattern:(NSString*)pattern selector:(SEL)sel; //SINCE 1.0.2
-(BOOL)registerPattern:(NSString*)pattern userInfo:(id)user; //SINCE 1.0.2
-(BOOL)registerPattern:(NSString*)pattern; //SINCE 1.0.2
-(BOOL)registerNamedPattern:(NSString*)name target:(id)target selector:(SEL)sel userInfo:(id)user; //SINCE 1.0.2
-(BOOL)registerNamedPattern:(NSString*)name target:(id)target selector:(SEL)sel; //SINCE 1.0.2
-(BOOL)registerNamedPattern:(NSString*)name selector:(SEL)sel userInfo:(id)user; //SINCE 1.0.2
-(BOOL)registerNamedPattern:(NSString*)name selector:(SEL)sel; //SINCE 1.0.2
-(BOOL)registerNamedPattern:(NSString*)name userInfo:(id)user; //SINCE 1.0.2
-(BOOL)registerNamedPattern:(NSString*)name; //SINCE 1.0.2
-(NSDictionary*)patternsPlist;

@end


BOOL HandleSpeechExtensions(NSString* refId, NSString* text, NSArray* tokens, NSSet* tokenset);
void AEExtensionBeginExclusive(NSObject<SECommand>* ex);
void AEExtensionEndExclusive();
void RequestCompleted();

#pragma mark - UNIVERSAL SIRI SNIPPET ---------------------------------------------------------------------------------
// Used as a proxy between user-supplied snippet from an extension and Assistant implementation

@interface SAK3AExtensionSnippet : SAUISnippet {
@private
}
- (id)encodedClassName;
- (id)groupIdentifier;
@end

@interface K3AExtensionSnippetController : AFUISnippetController {
    UIView* _view;
    NSObject<SESnippet>* _snip;
}

- (id)view;
- (void)dealloc;
- (id)initWithAceObject:(id)ace delegate:(id)dlg;
@end
