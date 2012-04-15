//
//  AEX.m
//  AssistantExtensions
//
//  Created by K3A on 3/19/12.
//  Copyright (c) 2012 K3A. All rights reserved.
//

#include <pcre.h>
#include <string.h>
#import "AEStringAdditions.h"

#import "AEX.h"

@implementation AEPatternMatchImpl

+(id)patternMatchForText:(NSString*)text language:(NSString*)lang userInfo:(id)ui
{
    AEPatternMatchImpl* pm = [[AEPatternMatchImpl alloc] initWithText:text language:lang userInfo:ui];
    return [pm autorelease];
}
-(id)initWithText:(NSString*)text language:(NSString*)lang userInfo:(id)ui
{
    if ( (self = [super init]) )
    {
        _text = [text retain];
        _lang = [lang retain];
        _userInfo = [ui retain];
        _namedElements = [[NSMutableDictionary alloc] init];
        _vectorElements = [[NSMutableArray alloc] init];
        
        _tokens = [[NSMutableArray alloc] initWithCapacity:1];
        NSScanner *scanner = [NSScanner scannerWithString:_text];
        NSString *token;
        while ([scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@" \t\r\n,.?!"] intoString:&token])
            [_tokens addObject:token];
        _tokenSet = [[NSSet alloc] initWithArray:_tokens];
    }
    return self;
}
-(void)dealloc
{
    [_text release];
    [_lang release];
    [_userInfo release];
    [_namedElements release];
    [_vectorElements release];
    [_tokens release];
    [_tokenSet release];
    [super dealloc];
}

-(NSString*)language
{
    return _lang;
}
-(NSString*)text
{
    return _text;
}
-(NSArray*)tokens
{
    return _tokens;
}
-(NSSet*)tokenSet
{
    return _tokenSet;
}
-(id)userInfo
{
    return _userInfo;
}

-(NSString*)namedElement:(NSString*)name
{
    return [_namedElements objectForKey:name];
}
-(NSString*)elementAtIndex:(unsigned)idx
{
    if (idx >= [_vectorElements count]) return nil;
    return [_vectorElements objectAtIndex:idx];
}
-(NSString*)firstElement
{
    if ([_vectorElements count] < 1) return nil;
    return [_vectorElements objectAtIndex:0];
}
-(NSString*)secondElement
{
    if ([_vectorElements count] < 2) return nil;
    return [_vectorElements objectAtIndex:1];
}
-(NSString*)thirdElement
{
    if ([_vectorElements count] < 3) return nil;
    return [_vectorElements objectAtIndex:2];
}
-(NSString*)fourthElement
{
    if ([_vectorElements count] < 4) return nil;
    return [_vectorElements objectAtIndex:3];
}

// private ---

-(void)addElement:(NSString*)elem
{
    if (!elem) return;
    
    NSString* e = [elem copy];
    [_vectorElements addObject:e];
    [e release];
}
-(void)addElement:(NSString*)elem forName:(NSString*)name
{
    if (!elem) return;
    
    NSString* e = [elem copy];
    
    if (name && [name length]) 
    {
        [_namedElements setObject:e forKey:name];
    }
    [_vectorElements addObject:e];
    [e release];
}

@end

#pragma mark - ===================================================================================

struct AEPatternToken {
    NSString* label;
    unsigned minWords; // minimum words to parse
    //unsigned maxWords; // maximum words to parse
    bool moreWords; // if this token represents more than one word
    bool optional; // whether the token is optional
    bool matchable; // whether token represents result
    bool _canBeSplitCached;
    bool _canBeSplit;
    
    // one of these is used, the other is NULL
    struct AEPatternSubtoken* subtoken; // if at least one subtoken matches, the whole pattern token matches
    pcre* regexp;
    
    struct AEPatternToken* next;
    
    bool CanBeSplit()
    {
        if (_canBeSplitCached) return _canBeSplit;
        
        struct AEPatternSubtoken* stok = subtoken;
        while(stok) 
        {
            if (stok->part2) { _canBeSplitCached=true; _canBeSplit=true; return _canBeSplit;}
            stok = stok->next;
        }
        _canBeSplitCached = true;
        _canBeSplit = false;
        return _canBeSplit;
    }
    
    bool MatchesWord(NSString* word, int wordPart) // wordPart: 0-whole word, 1-first part, 2-second part
    {
        // regexp
        if (regexp)
        {
            const char* inputPartStr = [word UTF8String];
            size_t inputPartLen = strlen(inputPartStr);
            int ovector[30];
            int rc = pcre_exec(regexp,             /* the compiled pattern */
                               NULL,                    /* no extra data - we didn't study the pattern */
                               inputPartStr,            /* the subject string */
                               (int)inputPartLen,       /* the length of the subject */
                               0,                       /* start at offset 0 in the subject */
                               0,                       /* default options */
                               ovector,                 /* output vector for substring information */
                               30);                     /* number of elements in the output vector */
            if (rc < 0) // regexp exec failed
            {
                if (rc == PCRE_ERROR_NOMATCH)
                {
                    if (!optional) return false;
                }
                else
                {
                    NSLog(@"AE ERROR: Pcre matching error %d!", rc);
                    return FALSE;
                }
            }
            else if (rc == 0)
            {
                NSLog(@"AE ERROR: Too many match results (%d)!", rc);
                if (!optional) return false;
            }
            return true;
        }
        
        // normal
        unsigned long wordHash = [word hash];
        struct AEPatternSubtoken* stok = subtoken;
        while(stok) 
        {
            if (stok->type == AEPatternSubtoken::EXACT)
            {
                if (wordPart == 2 && !stok->part2) goto nextToken; // this subtoken is not splittable
                if (wordPart == 0)
                {
                    if (stok->wordHash && stok->wordHash == wordHash) 
                        return true;
                    else if ([stok->word isEqualToString:word])
                        return true;
                }
                else if (wordPart == 1)
                {
                    if (stok->hash1 && stok->hash1 == wordHash)
                        return true;
                    else if ([stok->part1 isEqualToString:word])
                        return true;
                }
                else if (wordPart == 2)
                {
                    if (stok->hash2 && stok->hash2 == wordHash)
                        return true;
                    else if ([stok->part2 isEqualToString:word])
                        return true;
                }
            }
            else if (stok->type == AEPatternSubtoken::FUZZY)
            {
                if (wordPart == 2 && !stok->part2) goto nextToken; // this subtoken is not splittable
                if (wordPart == 0)
                {
                    if ([stok->word isFuzzyEqualTo:word])
                        return true;
                }
                else if (wordPart == 1)
                {
                    if ([stok->part1 isFuzzyEqualTo:word])
                        return true;
                }
                else if (wordPart == 2)
                {
                    if ([stok->part2 isFuzzyEqualTo:word])
                        return true;
                }
            }
            else if (stok->type == AEPatternSubtoken::WORD)
                return true;
            else if (stok->type == AEPatternSubtoken::NUMBER)
            {
                const char* str = [word UTF8String];
                bool wrong = false;
                while (*str)
                {
                    if (!isdigit(*str) && *str != '.') 
                    {
                        wrong = true;
                        break;
                    }
                    str++;
                }
                if (wrong) goto nextToken;
                return true;
            }
            else if (stok->type == AEPatternSubtoken::ALPHA)
            {
                const char* str = [word UTF8String];
                bool wrong = false;
                while (*str)
                {
                    if (!isalpha(*str))
                    {
                        wrong = true;
                        break;
                    }
                    str++;
                }
                if (wrong) goto nextToken;
                return true;
            }
            else if (stok->type == AEPatternSubtoken::ALPHANUM)
            {
                const char* str = [word UTF8String];
                bool wrong = false;
                while (*str)
                {
                    if (!isalnum(*str))
                    {
                        wrong = true;
                        break;
                    }
                    str++;
                }
                if (wrong) goto nextToken;
                return true;
            }
            else 
                goto nextToken;
            
        nextToken:
            stok = stok->next;
        }
        
        return false;
    }
};

#pragma mark - ===================================================================================

@implementation AEPattern

+(id)patternWithString:(NSString*)pat target:(id)target selector:(SEL)sel userInfo:(id)user
{
    return [[[AEPattern alloc] initWithPatternString:pat target:target selector:sel userInfo:user] autorelease];
}

-(NSString*)description
{
    return _description;
}

-(void)dealloc
{
    [_description release];
    [_target release];
    [_userInfo release];
    
    // release tokens
    struct AEPatternToken* tok = _first;
    while (tok) {
        struct AEPatternToken* nextTok = tok->next;
        [tok->label release];
        
        // release subtokens
        struct AEPatternSubtoken* stok = tok->subtoken;
        while(stok) {
            [stok->part1 release];
            [stok->part2 release];
            [stok->word release];
            stok = stok->next;
        }
        
        // pcre
        if (tok->regexp) pcre_free(tok->regexp);
        
        free(tok);
        tok = nextTok;
    }
    
    [super dealloc];
}

#define FAIL_STATE(reason) { NSLog(@"AE ERROR: " reason " in element '%s' (pattern '%@')", pch, pat); goto fail;   }

-(id)initWithPatternString:(NSString*)pat target:(id)target selector:(SEL)sel userInfo:(id)user
{
    // Note: braces must be in this order ([<word>])
    
    self = [super init];
    if (!self) return nil;
    _first = NULL;
    _target = [target retain];
    _sel = sel;
    _userInfo = [user retain];
    
    NSString* lowercasePat = [pat lowercaseString];
    
    _description = [[NSString stringWithFormat:@"'%@'", lowercasePat] retain];
    char* pattern = strdup([lowercasePat UTF8String]);
    bool optionalMatchableParsed = false;
    AEPatternToken* tok;
    ///NSLog(@" ");
    //NSLog(@">>> PATTERN '%s'", pattern);
    
    char* pch = strtok (pattern," \n\r\t");
    while (pch != NULL)
    {
        char* inPtr = pch;
        char* rawStart = NULL;
        char* rawEnd = NULL;
        char* labelStart = NULL;
        char* labelEnd = NULL;
        
        bool inMatchPar = false; // inside ()
        bool inTypePar = false; // inside <>
        bool inRegPar = false; // inside //
        bool inOptPar = false; // inside []
        
        bool regParsed = false;
        bool matchParsed = false;
        bool typeParsed = false;
        bool optParsed = false;
        bool plusParsed = false;
        bool asteriskParsed = false;
        
        while (*inPtr)
        {
            if (*inPtr == '/' && inRegPar) //regexp end
            {
                regParsed = true; 
                inRegPar = false;
                if (!rawEnd) rawEnd = inPtr;
            }
            else if (inRegPar) { // regexp body
                inPtr++;
                continue;
            }
            else if (*inPtr == '(')
            {
                if (inMatchPar) FAIL_STATE("Unexpected second '('");
                if (matchParsed) FAIL_STATE("Only one (..) block is allowed");
                if (inTypePar || inOptPar) FAIL_STATE("Wrong order of braces must be ([<...>])");
                inMatchPar = true;
            }
            else if (*inPtr == '<')
            {
                if (inTypePar) FAIL_STATE("Unexpected second '<'");
                if (typeParsed) FAIL_STATE("Only one <..> block is allowed");
                if (rawStart && !labelEnd) FAIL_STATE("Garbage at the beginning");
                inTypePar = true;
                rawStart = inPtr;
            }
            else if (*inPtr == '[')
            {
                if (inOptPar) FAIL_STATE("Unexpected second '['");
                if (optParsed) FAIL_STATE("Only one [..] block is allowed");
                if (inTypePar) FAIL_STATE("Wrong order of braces must be ([<...>])");
                if (rawStart && !labelEnd) FAIL_STATE("Garbage at the beginning");
                inOptPar = true;
            }
            else if (*inPtr == ':')
            {
                if (!labelStart) FAIL_STATE("Missing label name");
                labelEnd = inPtr;
                rawStart = inPtr+1;
            }
            else if (*inPtr == ')')
            {
                if (!inMatchPar) FAIL_STATE("Unexpected ')'");
                if (inTypePar) FAIL_STATE("Expected '>' before ')'");
                if (inOptPar) FAIL_STATE("Expected ']' before ')'");
                inMatchPar = false;
                matchParsed = true;
                if (!rawEnd) rawEnd = inPtr;
            }
            else if (*inPtr == '>')
            {
                if (!inTypePar) FAIL_STATE("Unexpected '>'");
                inTypePar = false;
                typeParsed = true;
                if (!rawEnd) rawEnd = inPtr+1;
            }
            else if (*inPtr == ']')
            {
                if (!inOptPar) FAIL_STATE("Unexpected ']'");
                if (inTypePar) FAIL_STATE("Expected '>' before ']'");
                inOptPar = false;
                optParsed = true;
                if (!rawEnd) rawEnd = inPtr;
            }
            else if (*inPtr == '/') // regexp begin
            {
                if (!inRegPar && regParsed) FAIL_STATE("Unexpected '/'");
                inRegPar = true;
                rawStart = inPtr+1;
            } 
            else if (*inPtr == '+')
            {
                if (!typeParsed) FAIL_STATE("Unexpected '+'");
                plusParsed = true;
            }
            else if (*inPtr == '*')
            {
                if (!typeParsed) FAIL_STATE("Unexpected '*'");
                asteriskParsed = true;
            }
            else // other char
            {
                if (!labelStart) labelStart = inPtr;
                
                // raw start
                if (!rawStart) rawStart = inPtr; // raw start for nonmatchable element
                
                // check for garbage at the end
                if ( labelEnd // has label but is already parsed
                    && inMatchPar && rawEnd) FAIL_STATE("Garbage at the end"); // garbage after raw body (rawEnd), after label, for matchable element
            }
            
            inPtr++;
        }
        if (!rawEnd) rawEnd = inPtr; // end body
        
        if (!rawStart && !regParsed) FAIL_STATE("Missing body");
        if (rawEnd-rawStart == 0) FAIL_STATE("Empty body");
        if (labelStart >= rawEnd) FAIL_STATE("Bad label");
        if (inMatchPar) FAIL_STATE("Missing ')'");
        if (inTypePar) FAIL_STATE("Missing '>'");
        if (inRegPar) FAIL_STATE("Missing ending '/'");
        if (inOptPar) FAIL_STATE("Missing ']'");
        
        
        // check order of optional matchables
        if (optionalMatchableParsed && matchParsed && !optParsed)
            FAIL_STATE("Optional matchable words must be at the end");
        if (optParsed && matchParsed)
            optionalMatchableParsed = true;
        
        // body
        unsigned tbodyLen = (unsigned)(rawEnd-rawStart);
        char* tbody = (char*)malloc(tbodyLen+1);
        strncpy(tbody, rawStart, tbodyLen);
        tbody[tbodyLen] = 0;
        // label
        unsigned tlabelLen = (unsigned)(labelEnd-labelStart);
        if (!labelEnd) tlabelLen=0;
        char* tlabel = (char*)malloc(tlabelLen+1);
        strncpy(tlabel, labelStart, tlabelLen);
        tlabel[tlabelLen] = 0;
        
        // print token with parsed data for debug
        //NSLog(@"--- %s%s%sTOKEN '%s' label '%s'", matchParsed?"MATCHABLE ":"", optParsed?"OPTIONAL ":"", regParsed?"REGEXP ":"", tbody, tlabel);
        
        // TODO: process body to find | <word>*+ or ~a a~b
        tok = (AEPatternToken*)malloc(sizeof(AEPatternToken));
        if (!tlabel || !*tlabel) 
            tok->label = nil;
        else
            tok->label = [[NSString stringWithUTF8String:tlabel] retain];
        
        tok->minWords = 0;
        if (plusParsed) tok->minWords = 1;
        tok->moreWords = asteriskParsed || plusParsed;
        tok->optional = optParsed || asteriskParsed;
        tok->matchable = matchParsed;
        tok->subtoken = NULL;
        tok->regexp = NULL;
        tok->_canBeSplit = tok->_canBeSplitCached = false;
        
        if (regParsed) // pcre regexp
        {
            const char *err_msg;
            int err;
            
            tok->regexp = pcre_compile(tbody, PCRE_UTF8/*|PCRE_CASELESS*/, &err_msg, &err, NULL);
            if (!tok->regexp)
            {
                NSLog(@"AE ERROR: Regexp error %d '%s' in element '%s' (pattern '%@')", err, err_msg, pch, pat); 
                goto fail;
            }
        }
        else // normal word - AE expression
        {
            // split words by |
            char* strtok2;
            pch = strtok_r(tbody,"|",&strtok2);
            while (pch != NULL)
            {
                // find ~ inside word
                char* firstPart = pch;
                char* secondPart = NULL;
                char* tmp = pch+1;
                while (*tmp) {
                    if (*tmp == '~') {
                        *tmp = 0;
                        secondPart = tmp+1;
                        break;
                    }
                    tmp++;
                }
                
                struct AEPatternSubtoken* stok = (AEPatternSubtoken*)malloc(sizeof(AEPatternSubtoken));
                
                // fuzzy?
                if (firstPart[0] == '~')
                {
                    stok->type = AEPatternSubtoken::FUZZY;
                    firstPart++;
                }
                else
                {
                    stok->type = AEPatternSubtoken::EXACT;
                    if (typeParsed)
                    {
                        if (!strcmp(tbody, "<word>"))
                            stok->type = AEPatternSubtoken::WORD;
                        else if (!strcmp(tbody, "<number>") || !strcmp(tbody, "<num>"))
                            stok->type = AEPatternSubtoken::NUMBER;
                        else if (!strcmp(tbody, "<alpha>"))
                            stok->type = AEPatternSubtoken::ALPHA;
                        else if (!strcmp(tbody, "<alphanum>"))
                            stok->type = AEPatternSubtoken::ALPHANUM;
                        else if (!strcmp(tbody, "<person>"))
                            stok->type = AEPatternSubtoken::PERSON;
                        else
                            FAIL_STATE("Unknown word type")
                            }
                }
                
                // add word
                stok->part1 = stok->part2 = stok->word = nil;
                stok->hash1 = stok->hash2 = stok->wordHash = 0;
                if (!secondPart)
                {
                    stok->word = [[NSString stringWithUTF8String:firstPart] retain];
                    stok->wordHash = [stok->word hash];
                    //NSLog(@"WORD: '%@'", stok->word);
                }
                else
                {
                    // parts
                    stok->part1 = [[NSString stringWithUTF8String:firstPart] retain];
                    stok->hash1 = [stok->part1 hash];
                    stok->part2 = [[NSString stringWithUTF8String:secondPart] retain];
                    stok->hash2 = [stok->part2 hash];
                    // whole word
                    size_t l1 = strlen(firstPart);
                    size_t l2 = strlen(secondPart);
                    char* wholeWord = (char*)malloc( l1 + l2 + 1 );
                    strcpy(wholeWord, firstPart);
                    strcpy(&wholeWord[l1], secondPart);
                    stok->word = [[NSString stringWithUTF8String:wholeWord] retain];
                    stok->wordHash = [stok->word hash];
                    free(wholeWord);
                    //NSLog(@"WHOLE: '%@' PART1:'%@' PART2:'%@'", stok->word, stok->part1, stok->part2);
                }
                
                // add subtoken
                stok->next = tok->subtoken;
                tok->subtoken = stok;
                
                pch = strtok_r(NULL,"|",&strtok2);
            }
        }
        
        // cache can be split
        tok->CanBeSplit();
        
        free(tbody);
        free(tlabel);
        
        // add token to the end
        AEPatternToken* lastTok = _first;
        while (lastTok && lastTok->next)
            lastTok = lastTok->next;
        
        tok->next = NULL;
        if (lastTok) 
            lastTok->next = tok;
        else
            _first = tok;
        
        // next token
        pch = strtok (NULL, " \n\r\t");
    }
    
    // check for good pattern form
    tok = _first;
    while (tok)
    {
        if (tok->moreWords && tok->next) // find a stop word
        {
            if (tok->next->moreWords)
                FAIL_STATE("Pattern uses two or more multiple-word tokens (like <word>*) in a row!")
            
            /*bool gotStopWord = false;
            AEPatternToken* tmpt = tok->next;
            while (tmpt)
            {
                if (!tmpt->moreWords && !tmpt->subtoken->type != AEPatternSubtoken::WORD && !tmpt->optional)
                {
                    gotStopWord = true;
                    break;
                }
                tmpt = tmpt->next;
            }
            
            if (!gotStopWord)
                FAIL_STATE("Pattern uses multiple-word tokens (like <word>*) but there is not a stop word!")*/
        }
        tok = tok->next;
    }
    
    free(pattern);
    return self;
    
fail:
    free(pattern);
    [self release];
    return nil;
}

-(BOOL)fireWithMatch:(id<AEPatternMatch>)match context:(id<SEContext>)ctx
{
    NSLog(@"AE: Invoking target %@ (%s) using the selector %s", _target, object_getClassName(_target), (const char*)_sel);
    
    NSMethodSignature* sig = [_target methodSignatureForSelector:_sel];
    NSInvocation* inv = [NSInvocation invocationWithMethodSignature:sig];
    [inv setSelector:_sel];
    [inv setTarget:_target];
    [inv setArgument:&match atIndex:2]; // match
    [inv setArgument:&ctx atIndex:3]; // context
    [inv invoke];
    
    BOOL val = FALSE;
    [inv getReturnValue:&val];
    
    return val;
}

-(BOOL)execute:(NSString*)input language:(NSString*)lang context:(id<SEContext>)ctx
{
    if (!_first || [input length] == 0) return FALSE;
    
    NSString* lcInput = [input lowercaseString];
    NSArray* inputTokens = [lcInput componentsSeparatedByString:@" "];
    NSEnumerator* enumer = [inputTokens objectEnumerator];
    
    AEPatternToken* currentToken = _first;
    int currentWordPart = 0;
    
    AEPatternMatchImpl* match = [AEPatternMatchImpl patternMatchForText:lcInput language:lang userInfo:_userInfo];
    NSMutableString* currElem = [NSMutableString string];
    bool firstWordOfElem = true;
    
    //Break([[input lowercaseString] isEqualTo:@"special you tube fone"] && [[self description] isEqualTo:@"'special You~Tube [~fone]'"]);
    
    unsigned inpTokNum = 0;
    NSString* inpTok = [enumer nextObject];
    while(inpTok)
    {
        //Break([inpTok isEqualTo:@"phone"]);
        inpTokNum++;
        
        bool doNotGetNextInputToken = false;
        
        // try normally first
        bool currTokMatches = currentToken->MatchesWord(inpTok, 0);
        
        // inform REF1 that it should get next aex for the next iteration (like if was second part of spitword aex)
        if (currentWordPart == 0 && currTokMatches && currentToken->CanBeSplit())
            currentWordPart = 2;
        
        // if not matched, it may be the first input word of a~b splittable aex
        if (!currTokMatches && currentToken->CanBeSplit()) 
        {
            currTokMatches = currentToken->MatchesWord(inpTok, 1+currentWordPart);
            currentWordPart++;
        }
        
        // skip optional non-matched aex tokens
        if (!currTokMatches && !currentToken->optional) // not matched and not optional, whole input phrase not matched
            return FALSE;
        else if (!currTokMatches && currentToken->optional) // optional and not matched, get next aex token
        {
            currentToken = currentToken->next;
            if (!currentToken) return FALSE; // it was last optional aex but not matched!
            inpTokNum--;
            continue;
        }
        
        // ... aex and input token matched ...
        
        // add token to current element if it's matchable
        if (currentToken->matchable)
        {
            if (firstWordOfElem)
            {
                [currElem appendString:inpTok];
                firstWordOfElem = false;
            }
            else
                [currElem appendFormat:@" %@", inpTok];
        }
        
        // ... next token ...
        
        // multi-word aex token? Eat input tokens until the stop token is found
        if (currentToken->moreWords)
        {
            unsigned numInpTokensForMultiwordAex = 1;
            
            while ( (inpTok = [enumer nextObject]) )
            {
                if (!inpTok) break;
                inpTokNum++;
                numInpTokensForMultiwordAex++;
                
                // try to find the nearest, non-optional stop aex word
                bool currInpTokIsAtStopAexWord = false;
                AEPatternToken* tmpt = currentToken->next;
                while (tmpt)
                {
                    if (tmpt->moreWords) // we are too far - multiword aex is not a stop word
                        break;
                    else // ok, single word aex token, can be stop but can be optional
                    {
                        if (tmpt->MatchesWord(inpTok, 0))
                        {
                            if (tmpt->CanBeSplit())
                                currentWordPart = 1;
                            currInpTokIsAtStopAexWord = true;
                            break;
                        }
                        else if (!tmpt->optional) // not matched and not optional, currInpTokIsAtStopAexWord=false
                            break;
                    }
                    tmpt = tmpt->next;
                }
                
                if (currInpTokIsAtStopAexWord)
                {
                    // do not add to currElem string, as this will be done next iteration, after we are at the next aex token
                    doNotGetNextInputToken = true;
                    inpTokNum--;
                    numInpTokensForMultiwordAex--;
                    break;
                }
                else
                {
                    // add token to current element if it's matchable
                    if (currentToken->matchable)
                    {
                        if (firstWordOfElem)
                        {
                            [currElem appendString:inpTok];
                            firstWordOfElem = false;
                        }
                        else
                            [currElem appendFormat:@" %@", inpTok];
                    }
                }
            }
            
            // not enough input tokens for minimum-words-criterium in this aex multiword
            if (numInpTokensForMultiwordAex < currentToken->minWords)
                return FALSE;
            /*else if (numInpTokensForMultiwordAex > currentToken->minWords)
             return FALSE;*/ // TODO: max criterium
        }
        
        // we are done with the current aex token, add it to the match results if matchable
        if (currentToken->matchable)
        {
            [match addElement:currElem forName:currentToken->label];
            [currElem setString:@""];
            firstWordOfElem = true;
        }
        
        // get next aex token (only for non-split aex or after the second part was matched)
        if (!currentToken->CanBeSplit() || currentWordPart == 2) // REF1
        {
            currentToken = currentToken->next;
            if (!currentToken) break;
        }
        
        if (currentWordPart == 2) currentWordPart = 0;  // reset when in second part of a~b
        
        // get the next input token
        if (doNotGetNextInputToken == false)
            inpTok = [enumer nextObject];
    }
    
    // phrase mathed, but make sure it matched completely
    // = no current or next token (in case of the last aex token is multiword) + all input tokens must be ate 
    bool matched = inpTokNum == [inputTokens count];
    if (currentToken) // check that current token and next tokens are optional
    {
        while (currentToken)
        {
            if (!currentToken->optional)
            {
                matched = false;
                break;
            }
            currentToken = currentToken->next;
        }
    }
    
    // if matched and the target was set, call handling method
    if (matched && _target) 
    {
        matched = [self fireWithMatch:match context:ctx];
    }
    
    return matched;
}

-(id)target
{
    return _target;
}
-(SEL)selector
{
    return _sel;
}
-(id)userInfo
{
    return _userInfo;
}

@end














