#import "AEChatBotCommands.h"

#include <aiml/aiml.h>

#define EXTENSIONS_PATH "/Library/AssistantExtensions/"

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
id<SESystem> s_system = nil; // FIXME: quite hacky now...

static void SpeakAIMLError(id<SEContext> ctx, cInterpreter* interpret)
{
    s_aimlEndLoading = true;
    
    AIMLError err = s_aimlInterpreter->getError();
    string errStr = s_aimlInterpreter->getErrorStr(err);
    string errRuntime = s_aimlInterpreter->getRuntimeErrorStr();
    
    if (errRuntime.empty())
    {
        [ctx sendAddViewsUtteranceView:[NSString stringWithFormat:@"My brain just exploded!\nError %u: %s", 
                                        err, errStr.c_str()]];
    }
    else
        [ctx sendAddViewsUtteranceView:[NSString stringWithFormat:@"My brain just exploded!\nError %u: %s\nRuntime Error: %s", 
                                        err, errStr.c_str(), errRuntime.c_str()]];
    
    [ctx sendRequestCompleted];
}

static void* FunnyThreadMain(void* ref)
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    
    id<SEContext> ctx = (id<SEContext>)ref;
    
#define NUM_LOADING_STORIES 11
    NSString* loadingStory[] = {
        [s_system localizedString:@"It's hard to find some files..."],
        [s_system localizedString:@"There is so much data!"],
        [s_system localizedString:@"Aha, there it is..."],
        [s_system localizedString:@"Looks promising..."],
        [s_system localizedString:@"Just one more second..."],
        [s_system localizedString:@"It takes a bit more."],
        [s_system localizedString:@"Clever robots are complex..."],
        [s_system localizedString:@"Looking forward to chatting..."],
        [s_system localizedString:@"Stay here..."],
        [s_system localizedString:@"Ok, got it."],
        [s_system localizedString:@"Wait! Aha, I need this..."],
    };
    
    while(!s_aimlEndLoading)
    {
        sleep(5+rand()%13);
        NSString* text = loadingStory[rand()%NUM_LOADING_STORIES];
        [ctx sendAddViewsUtteranceView:text speakableText:text dialogPhase:@"Reflection" scrollToTop:NO temporary:NO];
    }
    
    [ctx release];
    
    [pool release];
    return NULL;
}

static NSString* s_currLang = nil; // FIXME: quite hacky, should be included as a parameter of thread mains 
static void* LoadThreadMain(void* ref)
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    
    id<SEContext> ctx = (id<SEContext>)ref;
    
    s_aimlEndLoading = false;
    s_aimlInterpreter = cInterpreter::newInterpreter(); 
    s_aimlInterpreter->registerCallbacks(&s_aimlCallbacks);
    
    // find the best index
    NSString* indexPath = [NSString stringWithFormat:@"%s/aiml/index_%@.xml", EXTENSIONS_PATH, s_currLang];
    NSFileManager* fm = [NSFileManager defaultManager];
    bool longLang = [s_currLang length]>2;
    if (![fm fileExistsAtPath:indexPath])
    {
        if (longLang) 
            indexPath = [NSString stringWithFormat:@"%s/aiml/index_%@.xml", EXTENSIONS_PATH, [s_currLang substringToIndex:2]];
        
        if (![fm fileExistsAtPath:indexPath])
            indexPath = [NSString stringWithFormat:@"%s/aiml/index.xml", EXTENSIONS_PATH];
    }
        
    if (!s_aimlInterpreter->initialize([indexPath UTF8String])) 
    {
        SpeakAIMLError(ctx, s_aimlInterpreter);
        cInterpreter::freeInterpreter(s_aimlInterpreter);
        s_aimlInterpreter = NULL;
        [ctx release];
        return NULL;
    }
    
    s_aimlEndLoading = true;
    
    [ctx sendAddViewsUtteranceView:[s_system localizedString:@"OK. I am ready! To stop chatting, just say goodbye..."]];
    [ctx sendRequestCompleted];
    
    [ctx release];
    [pool release];
    return NULL;
}

static bool InChatMode()
{
    return s_aimlInterpreter;
}

//-------------------------



@implementation AEChatBotCommands

-(id)initWithSystem:(id<SESystem>)system;
{
	if ( (self = [super init]) )
	{
		_system = system;
	}
	return self;
}

-(void)dealloc
{
	// additional cleaning
	[super dealloc];
}

-(BOOL)handleStartMatch:(id<AEPatternMatch>)match context:(id<SEContext>)ctx 
{
    [ctx beginExclusiveMode];
    [ctx sendAddViewsUtteranceView:[_system localizedString:@"Yep! Just a moment please until I load my brain..."]];
    
    s_system = _system;
    [s_currLang release];
    s_currLang = [[match language] copy];
    
    // create a funny thread
    pthread_t funnyThread;
    if ( pthread_create( &funnyThread, NULL, FunnyThreadMain, (void*)[ctx retain] ) != 0 )
        NSLog(@"Error: Failed to create Funny Thread!!");
    
    if (!s_aimlInterpreter) 
    {
        // create a interpreter loader
        pthread_t loadThread;
        if ( pthread_create( &loadThread, NULL, LoadThreadMain, (void*)[ctx retain] ) != 0 )
            NSLog(@"Error: Failed to create Load Thread!!");
    }
    
    return YES;
}

-(BOOL)handleSpeech:(NSString*)text tokens:(NSArray*)tokens tokenSet:(NSSet*)tokenset context:(id<SEContext>)ctx
{
    if (!InChatMode()) return NO;
    
    if (s_aimlInterpreter && !s_aimlEndLoading)
    {
        [ctx sendAddViewsUtteranceView:[_system localizedString:@"I am busy, please wait a few seconds..."]];
        [ctx sendRequestCompleted];
        return true;
    }
    else if (s_aimlInterpreter && 
             ([tokenset containsObject:[_system localizedString:@"bye"]] || [tokenset containsObject:[_system localizedString:@"goodbye"]]))
    {
        cInterpreter::freeInterpreter(s_aimlInterpreter);
        s_aimlInterpreter = NULL;
        [ctx sendAddViewsUtteranceView:[_system localizedString:@"Goodbye!"]];
        [ctx sendRequestCompleted];
        
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
                
                [ctx sendAddViewsUtteranceView:str];
            }
            
            [ctx sendRequestCompleted];
        }
        else 
        {
            SpeakAIMLError(ctx, s_aimlInterpreter);
            cInterpreter::freeInterpreter(s_aimlInterpreter);
            s_aimlInterpreter = NULL;
        }
        return true;
    }
    return false;
}

- (void)patternsForLang:(NSString*)lang inSystem:(id<SESystem>)system 
{
    [system registerNamedPattern:@"Start" target:self selector:@selector(handleStartMatch:context:)];
}

@end
// vim:ft=objc
