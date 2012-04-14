// iLockMyKids Source Code

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>
#import "SiriObjects_private.h"
#import "OS5Additions.h"

#import <locale.h>
#import <objc/runtime.h>
#include <substrate.h>

#import "main.h"
#import "shared.h"
#import "AESupport.h"

// concrete implementations
#include "systemcmds.h"
#include "AEExtension.h"

#import "AESpringBoardMsgCenter.h"
#import "AEAssistantdMsgCenter.h"

static NSMutableArray* s_regCls = nil; // class acronyms
static bool s_regDone = false; // whether acronyms are registered


static ADSession* s_lastSession = nil;
// assistantd - server2client
HOOK(ADSession, _handleAceObject$, void, id aceObj)
{
    //NSLog(@">> ADSession::_handleAceObject %@", aceObj);
    s_lastSession = self;
    
    NSDictionary* dict = [aceObj dictionary];
    NSDictionary* resp = IPCCallResponse(@"me.k3a.AssistantExtensions", @"Server2Client", [NSDictionary dictionaryWithObject:dict forKey:@"object"]);
    NSDictionary* respObj = [resp objectForKey:@"object"];
    if (respObj) SessionSendToClient(respObj); // it's the same as calling ORIG
}
END

// assistantd - client2server
HOOK(ADSession, sendCommand$, void, id cmd)
{
    s_lastSession = self;
    
    NSDictionary* dict = [cmd dictionary];
    NSDictionary* resp = IPCCallResponse(@"me.k3a.AssistantExtensions", @"Client2Server", [NSDictionary dictionaryWithObject:dict forKey:@"object"]);
    NSDictionary* respObj = [resp objectForKey:@"object"];
    if (respObj) SessionSendToServer(respObj); // it's the same as calling ORIG
}
END

// ... to add SAK3AExtension acronym (both, but mainly assistatd)
HOOK(BasicAceContext, init, id)
{
    // TODO: maybe cache and use only one context?
    //NSLog(@">> BasicAceContext:init");
    s_regDone = true;
    
    id orig = ORIG();
    [self addAcronym:@"SAK3AExtension" forGroup:@"me.k3a.ace.extension"];
    
    // needed only for custom acronyms for custom AceObjects
    /*for (NSDictionary* dict in s_regCls)
    {
        [self addAcronym:[dict objectForKey:@"acronym"] forGroup:[dict objectForKey:@"group"]];
        NSLog(@"...adding acronym %@ for group %@", [dict objectForKey:@"acronym"], [dict objectForKey:@"group"]);
    }*/
        
    return orig;
}
END

// bundle search paths for SBAssistantUIPluginManager (in SpringBoard)
/*HOOK(SBAssistantUIPluginManager, _bundleSearchPaths, id)
{
    NSMutableArray* arr = ORIG();
    
    [arr addObject:@"/Library/AssistantExtensions/"];
    //NSLog(@">> SBAssistantUIPluginManager:_bundleSearchPaths <%s> %@", object_getClassName(arr), arr);
    
    return arr;
}
END*/

#pragma mark - HELPER FUNCTIONS ---------------------------------------------------------------

id SessionSendToClient(NSDictionary* dict, id ctx)
{
    static Class AceObject = objc_getClass("AceObject");
    static Class BasicAceContext = objc_getClass("BasicAceContext");
 
    if (!dict) 
    {
        NSLog(@"AE ERROR: SessionSendToClient: nil dict as an argument!");
        return nil;
    }
    
    // create context
    if (ctx == nil) ctx = [[[BasicAceContext alloc] init] autorelease]; // ... is not needed normally, but just in case...
    
    //NSLog(@"###### ===> Sending Ace Object to Client: %@", dict);
    
    // create real AceObject
    id obj = [AceObject aceObjectWithDictionary:dict context:ctx];
    if (obj == nil) 
    {
        NSLog(@"AE ERROR: SessionSendToClient: NIL ACE OBJECT RETURNED FOR DICT: %@", dict);
        return nil;
    }
    else
    {
        //NSLog(@"SessionSendToClient <%s> from %@", object_getClassName(obj), dict);
    }
    
    // call the original method to handle our new object
    if (s_lastSession == nil) { return nil; }
    _ADSession$_handleAceObject$(s_lastSession, @selector(_handleAceObject:), obj);
    
    return obj;
}

id SessionSendToServer(NSDictionary* dict, id ctx)
{
    static Class AceObject = objc_getClass("AceObject");
    static Class BasicAceContext = objc_getClass("BasicAceContext");
    
    if (!dict) 
    {
        NSLog(@"AE ERROR: SessionSendToServer: nil dict as an argument!");
        return nil;
    }
    
    // create context
    if (ctx == nil) ctx = [[[BasicAceContext alloc] init] autorelease]; // ... is not needed normally, but just in case...
    
    //NSLog(@"###### ===> Sending Ace Object to Server: %@", dict);
    
    // create real AceObject
    id obj = [AceObject aceObjectWithDictionary:dict context:ctx];
    if (obj == nil) 
    {
        NSLog(@"AE ERROR: SessionSendToServer: NIL ACE OBJECT RETURNED FOR DICT: %@", dict);
        return nil;
    }
    else
    {
        //NSLog(@"SessionSendToClient <%s> from %@", object_getClassName(obj), dict);
    }
    
    _ADSession$sendCommand$(s_lastSession, @selector(sendCommand:), obj);
    
    return obj;
}

bool RegisterAcronymImpl(NSString* acronym, NSString* group)
{
    if (s_regDone)
    {
        NSLog(@"AE ERROR: You need to call this method from the initialize() function!");
        return false;
    }
    
    [s_regCls addObject:[NSDictionary dictionaryWithObjectsAndKeys:acronym,@"acronym", group,@"group", nil]];
    return true;
}

// springboard side
NSArray* GetAcronyms(){ s_regDone=true; NSLog(@"++++++++++ SENDING %u acronyms!", [s_regCls count]); return s_regCls; };

// assistantd side
/*static void CopyAcronymsFromSpringboardToAssistantd()
{
    NSArray* acronyms = [[[CPDistributedMessagingCenter centerNamed:@"me.k3a.AssistantExtensions"] sendMessageAndReceiveReplyName:@"GetAcronyms" userInfo:nil] objectForKey:@"acronyms"];
    if (acronyms) 
    {
        NSLog(@"++++++++++ RECEIVED %u acronyms!", [acronyms count]);
    
        [s_regCls autorelease];
        s_regCls = [acronyms mutableCopy];
    }
}*/

#pragma mark - INITIALIZATION CODE ---------------------------------------------------------------

static void Shutdown()
{
    NSLog(@"************* AssistantExtensions ShutDown *************");

    [s_regCls release];
    AESupportShutdown();
    
    //[[AESpringBoardMsgCenter sharedInstance] release];
    //[[AEAssistantdMsgCenter sharedInstance] release];
}

static void uncaughtExceptionHandler(NSException *exception) {
    NSLog(@"AE: CRASH DETECTED: %@", exception);
    NSLog(@"AE: Stack Trace: %@", [exception callStackSymbols]);
    // Internal error reporting
}

/*extern "C" NSArray* AFPreferencesSupportedLanguages();
static NSArray* (*original_AFPreferencesSupportedLanguages)();
static NSArray* replaced_AFPreferencesSupportedLanguages()
{
    NSArray* orig = original_AFPreferencesSupportedLanguages();
    NSMutableArray* repl = [NSMutableArray arrayWithArray:orig];
    [repl addObject:@"ja-JP"];
    
    return repl;
}*/

bool s_inSB = false;
extern "C" void Initialize();
extern "C" void Initialize() 
{
    unsigned startStamp = GetTimestampMsec();
    
	// Init
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    
	// bundle identifier
	NSString* bundleIdent = getAppIdentifier();
    
    NSLog(@"( AssistantExtensions init for %s )", [bundleIdent UTF8String]);
    

    if ( !bundleIdent || 
        (![bundleIdent isEqualToString:@"assistantd"] && ![bundleIdent isEqualToString:@"SpringBoard"])
       )
	{
		[pool release];
		return;
	}
    
    NSLog(@"************* AssistantExtensions %s init for %s ************* ", AE_VERSION, [bundleIdent UTF8String]);
    
    s_regCls = [[NSMutableArray alloc] init];
    
    // for custom acronyms
    GET_CLASS(BasicAceContext)
    LOAD_HOOK(BasicAceContext, init, init)
    
    if ([bundleIdent isEqualToString:@"SpringBoard"])
    {
        s_inSB = true;
        //sleep(2); // just in case (to avoid reboot crashes), probably can be removed later TODO

        [[AESpringBoardMsgCenter alloc] init];
        
        AESupportInit(true);
        
        //GET_CLASS(SBAssistantUIPluginManager)
        //LOAD_HOOK(SBAssistantUIPluginManager, _bundleSearchPaths, _bundleSearchPaths)

    }
    else if ([bundleIdent isEqualToString:@"assistantd"])
    {
        GET_CLASS(ADSession)
        LOAD_HOOK(ADSession, _handleAceObject:, _handleAceObject$)
        LOAD_HOOK(ADSession, sendCommand:, sendCommand$)
        
        //CopyAcronymsFromSpringboardToAssistantd(); // only needed for custom AceObjects
        
        [[AEAssistantdMsgCenter alloc] init];
        
        AESupportInit(false);
        
        atexit(&Shutdown);
    }
    
    [pool release];
    
    NSLog(@"AE: Init took %u ms", GetTimestampMsec() - startStamp);
    
    //MSHookFunction(AFPreferencesSupportedLanguages, replaced_AFPreferencesSupportedLanguages, &original_AFPreferencesSupportedLanguages);
}

bool InSpringBoard()
{
    return s_inSB;
}


