//
//  AEX.h
//  AssistantExtensions
//
//  Created by K3A on 3/19/12.
//  Copyright (c) 2012 K3A. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SiriObjects.h"

@interface AEPatternMatchImpl : NSObject <AEPatternMatch> {
    NSString* _lang;
    NSString* _text;
    NSMutableArray* _tokens;
    NSSet* _tokenSet;
    id _userInfo;
    NSMutableDictionary* _namedElements;
    NSMutableArray* _vectorElements;
}

+(id)patternMatchForText:(NSString*)text language:(NSString*)lang userInfo:(id)ui;
-(id)initWithText:(NSString*)text language:(NSString*)lang userInfo:(id)ui;
-(void)addElement:(NSString*)elem;
-(void)addElement:(NSString*)elem forName:(NSString*)name;

@end

struct AEPatternSubtoken {
    
    enum eAEPST {
        EXACT = 0, // exact word match (including splitwords by ~) ; default
        FUZZY, // fuzzy matching (including splitwords by ~)
        WORD, // must be <word>
        ALPHA, // must be <alpha>
        NUMBER, // must be <number>
        ALPHANUM, // <alphanum>
        PERSON, // <person> addressbook lookup
    };
    
    NSString* part1; // only used for split words (a~b)
    NSString* part2; // only used for split words (a~b)
    NSString* word;
    unsigned long hash1; // token hash, 0 if not possible
    unsigned long hash2; // token hash, 0 if not possible
    unsigned long wordHash; // token hash, 0 if not possible
    enum eAEPST type;
    
    struct AEPatternSubtoken* next;
};

@interface AEPattern : NSObject {
@private
    struct AEPatternToken* _first;
    NSString* _description;
    id _target;
    SEL _sel;
    id _userInfo;
}
+(id)patternWithString:(NSString*)pat target:(id)target selector:(SEL)sel userInfo:(id)user;
-(id)initWithPatternString:(NSString*)pat target:(id)target selector:(SEL)sel userInfo:(id)user;

/// tries if this pattern matches and if so executes handling method and returns TRUE
-(BOOL)execute:(NSString*)input language:(NSString*)lang context:(id<SEContext>)ctx;
/// immediately fires the target on specified selector
-(BOOL)fireWithMatch:(id<AEPatternMatch>)match context:(id<SEContext>)ctx;

-(id)target;
-(SEL)selector;
-(id)userInfo;
@end




