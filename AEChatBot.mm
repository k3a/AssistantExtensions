//
//  AEChatBot.mm
//  SiriCommands
//
//  Created by K3A on 2/1/12.
//  Copyright (c) 2012 K3A. All rights reserved.
//

#import "AEChatBot.h"

#import "AESupport.h"
#import "SiriObjects.h"
#import "main.h"

#include <aiml/aiml.h>

using namespace std;
using namespace aiml;

class AIMLCallbacks : public cInterpreterCallbacks {
public:
    void onAimlLoad(const std::string& filename) {
        NSLog(@"AIML: Loaded %s", filename.c_str());
    }
} s_aimlCallbacks;
cInterpreter* s_aimlInterpreter = NULL;
bool s_aimlEndLoading = false;

static void SpeakAIMLError(NSString* refId, cInterpreter* interpret)
{
    s_aimlEndLoading = true;
    
    AIMLError err = s_aimlInterpreter->getError();
    string errStr = s_aimlInterpreter->getErrorStr(err);
    string errRuntime = s_aimlInterpreter->getRuntimeErrorStr();
    
    if (errRuntime.empty())
    {
        AESendToClient(SOCreateAceAddViewsUtteranceView(refId, [NSString stringWithFormat:@"My brain just exploded!\nError %u: %s", 
                                                                        err, errStr.c_str()]));
    }
    else
        AESendToClient(SOCreateAceAddViewsUtteranceView(refId, [NSString stringWithFormat:@"My brain just exploded!\nError %u: %s\nRuntime Error: %s", err, errStr.c_str(), errRuntime.c_str()]));
    
    AESendToClient(SOCreateAceRequestCompleted(refId));
}

static void* FunnyThreadMain(void* ref)
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    
#define NUM_LOADING_STORIES 11
    NSString* loadingStory[] = {
        @"It's hard to find some files...",
        @"There is so much data!",
        @"Aha, there it is...",
        @"Looks promising...",
        @"Just one more second...",
        @"It takes a bit more.",
        @"Clever robots are complex...",
        @"It's hard to find some files...",
        @"Stay here...",
        @"Ok, got it.",
        @"Wait! Aha, I need this...",
    };
    
    while(!s_aimlEndLoading)
    {
        sleep(5+rand()%13);
        AESendToClient(SOCreateAceAddViewsUtteranceView((NSString*)ref, loadingStory[rand()%NUM_LOADING_STORIES], nil, @"Reflection"));
    }
    
    [(id)ref release];
    
    [pool release];
    return NULL;
}

static void* LoadThreadMain(void* ref)
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    
    s_aimlEndLoading = false;
    s_aimlInterpreter = cInterpreter::newInterpreter(); 
    s_aimlInterpreter->registerCallbacks(&s_aimlCallbacks);
    
    if (!s_aimlInterpreter->initialize(EXTENSIONS_PATH"/aiml/index.xml")) 
    {
        SpeakAIMLError((NSString*)ref, s_aimlInterpreter);
        cInterpreter::freeInterpreter(s_aimlInterpreter);
        s_aimlInterpreter = NULL;
        return NULL;
    }
    
    s_aimlEndLoading = true;
    AESendToClient(SOCreateAceAddViewsUtteranceView((NSString*)ref, @"OK. I am ready! To stop chatting, just say goodbye..."));
    AESendToClient(SOCreateAceRequestCompleted((NSString*)ref));
    
    [pool release];
    return NULL;
}

bool InChatMode()
{
    return s_aimlInterpreter;
}
void StartChatMode(NSString* refId)
{
    NSMutableArray* views = [NSMutableArray arrayWithCapacity:1];
    [views addObject:SOCreateAssistantUtteranceView(@"Yep! Just a moment please until I load my brain...")];
    
    AESendToClient(SOCreateAceAddViews(refId, views));
    
    // create a funny thread
    pthread_t funnyThread;
    if ( pthread_create( &funnyThread, NULL, FunnyThreadMain, (void*)[refId copy] ) != 0 )
        NSLog(@"Error: Failed to create Funny Thread!!");
    
    if (!s_aimlInterpreter) 
    {
        // create a interpreter loader
        pthread_t loadThread;
        if ( pthread_create( &loadThread, NULL, LoadThreadMain, (void*)[refId copy] ) != 0 )
            NSLog(@"Error: Failed to create Load Thread!!");
    }
}

bool HandleChat(NSString* refId, NSString* text, NSArray* tokens, NSSet* tokenset)
{
    if (s_aimlInterpreter && !s_aimlEndLoading)
    {
        AESendToClient(SOCreateAceAddViewsUtteranceView(refId, @"I am busy, please wait a few seconds..."));
        AESendToClient(SOCreateAceRequestCompleted(refId));
        return true;
    }
    else if (s_aimlInterpreter && ([tokenset containsObject:@"bye"] || [tokenset containsObject:@"goodbye"])) // TODO: also free when siri closed
    {
        cInterpreter::freeInterpreter(s_aimlInterpreter);
        s_aimlInterpreter = NULL;
        AESendToClient(SOCreateAceAddViewsUtteranceView(refId, @"Goodbye!"));
        AESendToClient(SOCreateAceRequestCompleted(refId));
        NSLog(@"AE: Chatbot unloaded.");
        return true;
    }
    else if (s_aimlInterpreter && [tokenset count]>0)
    {
        string result;
        bool ok = s_aimlInterpreter->respond(string([text UTF8String]), "localhost", result, NULL); // TODO: log - last param
        if (ok)
        {
            const char* cstr = result.c_str();
            if (cstr)
            {
                NSMutableString* str = [NSMutableString stringWithUTF8String:cstr];
                
                static NSRegularExpression* regexp = nil;
                if (regexp == nil) 
                {
                    NSError* err = nil;
                    regexp = [[NSRegularExpression alloc] initWithPattern:@"\\$PAUSE(\\d+)?\\$" options:NSRegularExpressionCaseInsensitive|NSRegularExpressionDotMatchesLineSeparators error:&err];
                    if (err) NSLog(@"AE: Regexp error %@", [err description]);
                }
                [regexp replaceMatchesInString:str options:0 range:NSMakeRange(0, [str length]) withTemplate:@"@{tts#\e\\\\pause=$1\\\\}"];
                
                AESendToClient(SOCreateAceAddViewsUtteranceView(refId, str));
            }
            
            AESendToClient(SOCreateAceRequestCompleted(refId));
        }
        else 
        {
            SpeakAIMLError(refId, s_aimlInterpreter);
            cInterpreter::freeInterpreter(s_aimlInterpreter);
            s_aimlInterpreter = NULL;
        }
        return true;
    }
    return false;
}






