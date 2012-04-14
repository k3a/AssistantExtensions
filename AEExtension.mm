//
//  Extensions.mm
//  AssistantExtensions
//
//  Created by Kexik on 12/26/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
#include "AEExtension.h"

#include <dlfcn.h>
#include <unistd.h> // sleep

// directory listing
#include <sys/types.h>
#include <dirent.h>
#include <sys/stat.h>
#include <objc/runtime.h>

#import "main.h"
#import "AESupport.h"
#import "AEX.h"
#import "AESpringBoardMsgCenter.h"

static NSMutableDictionary* s_exDict = nil;

const char* extensionsPath = EXTENSIONS_PATH; // slash must be at the end
const int extensionsPathLen = strlen(extensionsPath);

#pragma mark - EXTENSION CLASS

@implementation AEExtension

+(BOOL)initExtensions
{
    s_exDict = [[NSMutableDictionary alloc] init];
    
    struct dirent *direntp = NULL;
    
    DIR *dirp = opendir(extensionsPath);
    if (dirp == NULL)
    {
        NSLog(@"AE ERROR: Error opening extensions dir %s. No extensions yet?", extensionsPath);
        return FALSE;
    }
    
    NSLog(@"AE: Loading Extensions:");
    while ((direntp = readdir(dirp)) != NULL)
    {
        // ignore special directories
        if ((strcmp(direntp->d_name, ".") == 0) ||
            (strcmp(direntp->d_name, "..") == 0))
            continue;
        
        // if not bundle, skip
        if (!strstr(direntp->d_name, ".assistantExtension")) continue;
        
        //TODO: remove .siribundle extension from name
         
        NSString* name = [NSString stringWithUTF8String:direntp->d_name];
        
        AEExtension* ex = [AEExtension extensionWithName:name];
        if (ex) [s_exDict setObject:ex forKey:[name lowercaseString]];
    }
    
    // finalize resources
    closedir(dirp);    
    
    return TRUE;
}

+(void)reloadExtensions
{
    NSLog(@"AE: Reloading Extensions:");
    [s_exDict removeAllObjects];
    
    struct dirent *direntp = NULL;
    
    DIR *dirp = opendir(extensionsPath);
    if (dirp == NULL)
    {
        NSLog(@"AE ERROR: Error opening extensions dir %s. No extensions yet?", extensionsPath);
        return;
    }
    
    while ((direntp = readdir(dirp)) != NULL)
    {
        /* Ignore special directories. */
        if ((strcmp(direntp->d_name, ".") == 0) ||
            (strcmp(direntp->d_name, "..") == 0))
            continue;
        
        // if not bundle, skip
        if (!strstr(direntp->d_name, ".assistantExtension")) continue;
        
        //TODO: remove .siribundle extension from name
        
        NSString* name = [NSString stringWithUTF8String:direntp->d_name];
        
        AEExtension* ex = [AEExtension extensionWithName:name];
        if (ex) [s_exDict setObject:ex forKey:[name lowercaseString]];
    }
    
    /* Finalize resources. */
    closedir(dirp);
}

+(void)shutdownExtensions
{
    [s_exDict release];
}

+(void)switchToLanguage:(NSString*)lang
{
    static NSString* oldLang = nil;
    if ([oldLang isEqualToString:lang])
        return;
    else
    {
        [oldLang release];
        oldLang = [lang copy];
    }
        
    for (NSString* key in [s_exDict allKeys])
    {
        [[s_exDict objectForKey:key] languageChangedTo:lang];
    }
    NSLog(@"AE: Language switched to %@", lang);
}

+(NSArray*)allExtensionsNames
{
    return [s_exDict allKeys];
}

+(NSArray*)allExtensions
{
    return [s_exDict allValues];
}

+(id)findExtensionNamed:(NSString*)name
{
    AEExtension* ex = [s_exDict objectForKey:name];
    return ex;
}

+(id)extensionWithName:(NSString*)name
{
    return [[[AEExtension alloc] initWithName:name] autorelease];
}

-(id)initWithName:(NSString*)name
{
    if (_initialized) 
    {
        NSLog(@"AE ERROR: Extension already initialized!");
        return nil;
    }
    
    if ( (self = [super init]) )
    {
        NSLog(@"-> %@", name);
        
        char full_name[_POSIX_PATH_MAX + 1];
        if ((extensionsPathLen + strlen([name UTF8String]) + 1) > _POSIX_PATH_MAX)
        {
            [self release];
            return nil;
        }
        
        strcpy(full_name, extensionsPath);
        strcat(full_name, [name UTF8String]);
        
        struct stat fstat;
        if (stat(full_name, &fstat) < 0)
        {
            NSLog(@"AE ERROR: Extension Bundle at path %s cannot be found!", full_name);
            [self release];
            return nil;
        }
        
        _bundle = [[NSBundle bundleWithPath:[NSString stringWithUTF8String:full_name]] retain];
        if (!_bundle)
        {
            NSLog(@"AE ERROR: Failed to open extension bundle %@ (%s)!", name, full_name);
            [self release];
            return nil;
        }
        
        if (![_bundle load])
        {
            NSLog(@"AE ERROR: Failed to load extension bundle %@ (wrong CFBundleExecutable? Missing? Not signed?)!", name);
            [self release];
            return nil;
        }
        
        // load principal class
        Class principal = [_bundle principalClass];
        if (!principal)
        {
            NSLog(@"AE ERROR: Extension %@ doesn't provide a NSPrincipalClass!", name);
            [self release];
            return nil;
        }
        
        // check version requirements
        NSString* verReq = [_bundle objectForInfoDictionaryKey:@"AEVersionRequirement"];
        if (!verReq && [_principal respondsToSelector:@selector(versionRequirement)])
            verReq = [_principal versionRequirement];
        
        if (verReq)
        {
            NSArray* verReqArr = [verReq componentsSeparatedByString:@"."];
            NSString* ver = @AE_VERSION;
            NSArray* verArr = [ver componentsSeparatedByString:@"."];
            
            int reqLen = [verReqArr count];
            int len = [verArr count];
            
            int toProcess = (reqLen > len)?reqLen:len; // find highest
            for (int i=0; i<toProcess; i++)
            {
                int rr = 0;
                int vv = 0;
                if (i<reqLen) rr = [[verReqArr objectAtIndex:i] intValue];
                if (i<len) vv = [[verArr objectAtIndex:i] intValue];
                
                if (rr > vv)
                {
                    NSLog(@"AE ERROR: Extension %@ requires AE %@ or newer but you have AE %@ installed!", name, verReq, ver);
                    [self release];
                    return nil;
                }
            }
        }
        
        _commands = [[NSMutableArray alloc] init];
        _snippets = [[NSMutableArray alloc] init];
        _patterns = [[NSMutableArray alloc] init];

        _principal = [[principal alloc] initWithSystem:self];
        if (!_principal)
        {
            NSLog(@"AE ERROR: Failed to initialize NSPrincipalClass from extension %@!", name);
            [self release];
            return nil;
        }
        else if (![_principal conformsToProtocol:@protocol(SEExtension)])
        {
            NSLog(@"AE ERROR: Extension's NSPrincipalClass (%s) doesn't conform to SEExtension protocol!", object_getClassName(_principal));
            [self release];
            return nil;
        }
        
        // get extension info
        _displayName = [[[_bundle infoDictionary] objectForKey:@"AEName"] copy];
        if (!_displayName)
        {
            if ([_principal respondsToSelector:@selector(name)])
                _displayName = [[_principal name] copy];
            else
                _displayName = [[name stringByDeletingPathExtension] retain];
        }
        _version = [[_bundle objectForInfoDictionaryKey:@"AEVersion"] copy];
        _author = [[_bundle objectForInfoDictionaryKey:@"AEAuthor"] copy];
        if (!_author && [_principal respondsToSelector:@selector(author)]) _author = [[_principal author] copy];
        _web = [[_bundle objectForInfoDictionaryKey:@"AEWebsite"] copy];
        if (!_web && [_principal respondsToSelector:@selector(website)]) _web = [[_principal website] copy];
        _desc = [[_bundle objectForInfoDictionaryKey:@"AEDescription"] copy];
        if (!_desc && [_principal respondsToSelector:@selector(description)]) _desc = [[_principal description] copy];
        _ident = [[_bundle objectForInfoDictionaryKey:@"CFBundleIdentifier"] copy];
        if (!_ident) _ident = [[NSString alloc] initWithFormat:@"me.k3a.%@", name];
        
        _preferenceBundle = [[_bundle pathForResource:[_bundle objectForInfoDictionaryKey:@"AEPreferenceBundle"] ofType:@"bundle"] copy];
        //NSLog(@"AE PREFERENCE BUNDLE IZ %@", _preferenceBundle);
        _hasPreferences = _preferenceBundle ? YES : NO;
        
        // since 1.0.2 - handling raw objects
        _respondsToClientToServer = [_principal respondsToSelector:@selector(clientToServerObject:context:)];
        _respondsToServerToClient = [_principal respondsToSelector:@selector(serverToClientObject:context:)];
        if (_respondsToClientToServer)
        {
            NSMutableString* str = [NSMutableString string];
            if (!_clientToServerFilter)
                [str setString:@" ALL (consider adding filters)"];
            else
                for (NSString* fname in _clientToServerFilter)
                    [str appendFormat:@" %@", fname];
            NSLog(@"   [OK] raw client->server objects:%@", str);
        }
        if (_respondsToServerToClient)
        {
            NSMutableString* str = [NSMutableString string];
            if (!_serverToClientFilter)
                [str setString:@" ALL (consider adding filters)"];
            else
                for (NSString* fname in _serverToClientFilter)
                    [str appendFormat:@" %@", fname];
            NSLog(@"   [OK] raw server->client objects:%@", str);
        }
        
        /*Class principal = [_bundle principalClass];
        if (!principal)
        {
            NSLog(@"AE ERROR: Extension %@ doesn't provide a NSPrincipalClass!", name);
            [self release];
            return nil;
        }
        
        _principal = [[principal alloc] initWithSystem:[SCSystem sharedInstance]];
        if (!_principal)
        {
            NSLog(@"AE ERROR: Failed to initialize NSPrincipalClass from extension %@!", name);
            [self release];
            return nil;
        }*/
        
        _name = [name copy];
        _initialized = YES;
        
        // initialize patterns
        [self languageChangedTo:AEGetAssistantLanguage()]; // TODO: detect changes of siri language in runtime as well
        
        unsigned pcnt = [_patterns count];
        if (pcnt>0) NSLog(@"   [OK] %d AEX pattern(s)", pcnt);
    }
    
    return self;
}

-(void)dealloc
{
    [_name release];
    [_displayName release];
    [_author release];
    [_web release];
    [_version release];
    [_desc release];
    [_ident release];
    [_principal release];
    [_commands release];
    [_snippets release];
    [_patterns release];
    [_bundle release];
    [_currLang release];
    [_currLangDict release];
    [_currLangDir release];
    [_patternsPlist release];
     
    [_serverToClientFilter release];
    [_clientToServerFilter release];
    
    [super dealloc];
}

/*-(id<SOExtension>)principalObject
{
    return _principal;
}*/

-(NSObject<SECommand>*)handleSpeech:(NSString*)text tokens:(NSArray*)tokens tokenSet:(NSSet*)tokenset context:(AEContext*)ctx
{
    // forced command from the previous refId (context)
    if (_nextPattern)
    {
        AEPattern* p = _nextPattern;
        [p fireWithMatch:nil context:ctx];
        _nextPattern = nil;
        [p autorelease];
        return [p target];
    }
    else if (_nextCommand)
    {
        NSObject<SECommand>* cmd = _nextCommand;
        [cmd handleSpeech:text tokens:tokens tokenSet:tokenset context:ctx];
        _nextCommand = nil;
        return [cmd autorelease];
    }

    // try patterns first
    AEPattern* matchedPattern = NULL;
    for (AEPattern* p in _patterns)
    {
        //NSLog(@"AE: Testing input '%@' for pattern %@", text, p);
        if ([p execute:text language:_currLang context:ctx]) 
        {
            matchedPattern = p;
            break;
        }
    }
    
    if (matchedPattern) // some pattern matched
    {
        if ([ctx wasListenAfterSpeaking]) // needs this extension next time?
        {
            _nextPattern = [matchedPattern retain];
        }
        return [matchedPattern target];
    }
    else // old "handleSpeech" method
    {
        for (NSObject<SECommand>* cmd in _commands)
        {
            if ([cmd respondsToSelector:@selector(handleSpeech:tokens:tokenSet:context:)] && 
                [cmd handleSpeech:text tokens:tokens tokenSet:tokenset context:ctx])
            {
                if ([ctx wasListenAfterSpeaking]) // needs this extension next time?
                    _nextCommand = [cmd retain];
                
                return cmd;
            }
        }
    }
    return nil;
}

-(NSObject<SESnippet>*)allocSnippet:(NSString*)snippetClass properties:(NSDictionary *)props
{
    // TODO: speed up
    for (NSString* sn in _snippets)
    {
        if ([sn isEqualToString:snippetClass])
        {
            NSObject<SESnippet>* snip = [objc_getClass([snippetClass UTF8String]) alloc];
            
            id initRes = nil;
            if ([snip respondsToSelector:@selector(initWithProperties:system:)])
                 initRes = [snip initWithProperties:props system:self];
                 
            if (!initRes && [snip respondsToSelector:@selector(initWithProperties:)])
                initRes = [snip initWithProperties:props];
            
            if (!initRes) 
                initRes = [snip init];
            
            if (!initRes)
            {
                NSLog(@"AE ERROR: Snippet class %@ failed to initialize!", snippetClass);
                return nil;
            }
            return snip;
        }
    }
    
    return nil;
}
-(NSString*)name
{
    return _name;
}
-(NSString*)displayName
{
    if (!_displayName) return @"Unknown";
    return _displayName;
}

-(NSString*)author
{
    return _author?_author:@"";
}
-(NSString*)website
{
    return _web?_web:@"";
}
-(NSString*)description
{
    return _desc?_desc:@"";
}
-(NSString*)version
{
    return _version?_version:@"";
}
-(NSString*)preferenceBundle {
    if (!_preferenceBundle) return @"";
	return _preferenceBundle;
}

- (BOOL)hasPreferenceBundle {
	return _hasPreferences;
}

- (NSString *)iconPath 
{
	NSString *k = [_bundle objectForInfoDictionaryKey:@"AEIcon"];
    NSFileManager* fm = [NSFileManager defaultManager];
    
    if (!k || !_bundle) return @"";
    NSString* iconPath = [NSString stringWithFormat:@"%@/%@", [_bundle bundlePath], k];
    if (![fm fileExistsAtPath:iconPath])
        iconPath = [NSString stringWithFormat:@"%@/%@.png", [_bundle bundlePath], k];
    
	return iconPath;
}
-(NSString*)identifier
{
    return _ident;
}

- (BOOL)enabled 
{
    //NSNumber* e = [[NSDictionary dictionaryWithContentsOfFile:[self pathToInfoDictionary]] objectForKey:@"AEEnabled"];
    NSNumber* e = [[AESpringBoardMsgCenter sharedInstance] prefForKey:[self identifier]];
    
    return !e || [e boolValue];
}

- (NSString*)pathToInfoDictionary 
{
    NSString* path = [_bundle pathForResource:@"Info" ofType:@"plist"];
	return path?path:@"";
}

-(BOOL)handlesServerToClientClass:(NSString*)className;
{
    if (!_respondsToServerToClient) return NO;
    if (!_serverToClientFilter) return YES;
    return [_serverToClientFilter containsObject:className];
}
-(BOOL)handlesClientToServerClass:(NSString*)className;
{
    if (!_respondsToClientToServer) return NO;
    if (!_clientToServerFilter) return YES;
    return [_clientToServerFilter containsObject:className];
}
-(NSDictionary*)serverToClient:(NSDictionary*)input context:(AEContext*)ctx
{
    return [_principal serverToClientObject:[[input mutableCopy] autorelease] context:ctx];
}
-(NSDictionary*)clientToServer:(NSDictionary*)input context:(AEContext*)ctx
{
    return [_principal clientToServerObject:[[input mutableCopy] autorelease] context:ctx];
}
-(void)callAssistantDismissed
{
    // call to each commands class
    for (NSObject<SECommand>* cmd in _commands)
    {
        if ([cmd respondsToSelector:@selector(assistantDismissed)])
            [cmd assistantDismissed];
    }
    
    // call to extension's principal
    if ([_principal respondsToSelector:@selector(assistantDismissed)])
        [_principal assistantDismissed];
}
-(void)callAssistantActivated
{
    // call to extension's principal
    if ([_principal respondsToSelector:@selector(assistantActivatedWithContext:)])
        [_principal assistantActivatedWithContext:[AEContext contextWithRefId:nil]];
}
-(void)languageChangedTo:(NSString*)lang
{
    if ([lang isEqualToString:_currLang]) 
    {
        NSLog(@"AE: Already on the lang %@. Not re-loading.", lang);
        return; // already using the same lang
    }
    
    NSString* resPath = [_bundle resourcePath];
    NSFileManager* fm = [NSFileManager defaultManager];
    NSArray* subpaths = [fm subpathsAtPath:resPath];
    
    [_currLangDir release];
    _currLangDir = nil;
    
    for (NSString* sp in subpaths)
    {
        if ([sp hasSuffix:@".lproj"])
        {
            NSString* lname = [sp stringByDeletingPathExtension];
            if ([lname caseInsensitiveCompare:lang] == NSOrderedSame) // exact match
            {
                _currLangDir = [resPath stringByAppendingFormat:@"/%@.lproj", lname];
                break;
            }
            else if ([lname hasPrefix:lang] || [lang hasPrefix:lname]) // partial match
            {
                _currLangDir = [resPath stringByAppendingFormat:@"/%@.lproj", lname];
            }
        }
    }
    
    if (!_currLangDir)
    {
        _currLangDir = [resPath stringByAppendingFormat:@"/en.lproj"];
        if (![fm fileExistsAtPath:_currLangDir])
        {
            //NSLog(@"AE: Info: The language directory not found for the language '%@' nor 'en'. Not using localization.", lang);
            _currLangDir = nil;
        }
        else
            NSLog(@"AE: Info: A language directory for the language '%@' was not found. Using English.", lang);
    }
    
    // load Localizable.strings
    if (_currLangDir)
    {
        [_currLang release];
        _currLang = [lang copy];
        
        NSString* stringsPath = [_currLangDir stringByAppendingFormat:@"/Localizable.strings"];
        [_currLangDict release];
        _currLangDict = [[NSDictionary alloc] initWithContentsOfFile:stringsPath];
        
        if (!_currLangDict)
            NSLog(@"AE: Info: File %@ was not found. Not using localization!", stringsPath);
        
        [_currLangDir retain];
    }
    
    // load patterns
    NSString* patternFile = [_currLangDir stringByAppendingString:@"/Patterns.plist"];
    if (![fm fileExistsAtPath:patternFile])
    {
        patternFile = [resPath stringByAppendingFormat:@"/en.lproj/Patterns.plist"];
        if (![fm fileExistsAtPath:patternFile])
        {
            patternFile = [resPath stringByAppendingFormat:@"/Patterns.plist"];
            if (![fm fileExistsAtPath:patternFile])
                patternFile = nil;
        }
    }
    if (patternFile)
    {
        [_patternsPlist release]; // delete the old one
        _patternsPlist = [[NSDictionary alloc] initWithContentsOfFile:patternFile];
        if (!_patternsPlist)
            NSLog(@"AE: Error: Patterns.plist file for %@ extension can't be loaded (damaged or malformed?)!", [self name]);
        else
            NSLog(@"   [OK] using Patterns.plist");
    }
    else
    {
        _patternsPlist = nil;
    }
    
    // remove old patterns
    [self removeAllPatterns];
    
    // register patterns of each command class
    for (id<SECommand> cmd in _commands)
    {
        if (![cmd respondsToSelector:@selector(patternsForLang:inSystem:)]) continue;
        
        _commandForCurrentPatternRegistrations = [cmd retain];
        [cmd patternsForLang:_currLang inSystem:self];
        _commandForCurrentPatternRegistrations = nil;
        [cmd release];
    }
}

// --- public methods (SESystem) --------------------------------------------------

-(BOOL)setServerToClientFilter:(NSArray*)allowedClasses
{
    _serverToClientFilter = [[NSSet setWithArray:allowedClasses] retain];
    return YES;
}
-(BOOL)setClientToServerFilter:(NSArray*)allowedClasses
{
    _clientToServerFilter = [[NSSet setWithArray:allowedClasses] retain];
    return YES;
}

-(BOOL)registerCommand:(Class)cls
{
    const char* clsName = class_getName(cls);
    
    if (![cls conformsToProtocol:@protocol(SECommand)])
    {
        NSLog(@"   [ER] command %s does not conform to protocol SECommand!", clsName);
        return NO;
    }
    
    // alloc
    id inst = [cls alloc];
    
    // init 1.0.2
    if ([inst respondsToSelector:@selector(initWithSystem:)])
        [inst initWithSystem:self];
    else
        [inst init];
    
    if (!inst)
    {
        NSLog(@"   [ER] command %s failed to initialize!", clsName);
        return NO;
    }
    
    [_commands addObject:inst];
    [inst release];

    NSLog(@"   [OK] command %s", clsName);
    
    return YES;
}
-(BOOL)registerSnippet:(Class)cls
{
    const char* clsName = class_getName(cls);
    
    if (![cls conformsToProtocol:@protocol(SESnippet)])
    {
        NSLog(@"   [ER] snippet %s does not conform to protocol SESnippet!", clsName);
        return NO;
    }
    
    NSLog(@"   [OK] snippet %s", clsName);
    [_snippets addObject:[NSString stringWithUTF8String:clsName]];
    
    return YES;
}
-(NSString*)systemVersion
{
	return @AE_VERSION;
}
//
-(NSString*)localizedString:(NSString*)text
{
    if (!_currLangDict) return text;
    
    NSString* localized = [_currLangDict objectForKey:text];
    
    if (localized)
        return localized;
    else 
        return text;
}
-(NSString*)localizedString:(NSString*)text inLanguage:(NSString*)lang
{
    return @"!NOT_IMPLEMENTED_YET!"; // TODO:
}
-(void)removeAllPatterns
{
    [_nextPattern release];
    _nextPattern = nil;
    [_patterns removeAllObjects];
}
// CONCRETE IMPLEMENTATION
-(BOOL)registerPattern:(NSString*)pattern target:(id)target selector:(SEL)sel userInfo:(id)user
{
    if (!_commandForCurrentPatternRegistrations)
    {
        NSLog(@"AE: ERROR: registerPattern called outside patternsForLang:inSystem: method!");
        return FALSE;
    }
    
    if (!pattern || [pattern length] == 0)
    {
        NSLog(@"AE ERROR: Missing or empty pattern!");
        return FALSE;
    }
    else if (!target)
    {
        NSLog(@"AE ERROR: No target specified for pattern '%@'!", pattern);
        return FALSE;
    }
    else if (![target respondsToSelector:sel])
    {
        NSLog(@"AE ERROR: Pattern '%@' registered with selector %s not available in target %p!", pattern, (const char*)sel, target);
        return FALSE;
    }
    else if (!sel)
    {
        NSLog(@"AE ERROR: No selector specified for pattern '%@'!", pattern);
        return FALSE;
    }
    
    AEPattern* p = [AEPattern patternWithString:pattern target:target selector:sel userInfo:user];
    if (!p) return FALSE;
    
    [_patterns addObject:p];
    
    return TRUE;
}
-(BOOL)registerPattern:(NSString*)pattern target:(id)target selector:(SEL)sel
{
    return [self registerPattern:pattern target:target selector:sel userInfo:nil];
}
-(BOOL)registerPattern:(NSString*)pattern selector:(SEL)sel userInfo:(id)user
{
    return [self registerPattern:pattern target:_commandForCurrentPatternRegistrations selector:sel userInfo:user];
}
-(BOOL)registerPattern:(NSString*)pattern selector:(SEL)sel
{
    return [self registerPattern:pattern selector:sel userInfo:nil];
}
-(BOOL)registerPattern:(NSString*)pattern userInfo:(id)user
{
    return [self registerPattern:pattern selector:@selector(handlePatternMatch:context:) userInfo:user];
}
-(BOOL)registerPattern:(NSString*)pattern
{
    return [self registerPattern:pattern selector:@selector(handlePatternMatch:context:) userInfo:nil];;
}
//-----------
// CONCRETE IMPLEMENTATION
-(BOOL)registerNamedPattern:(NSString*)name target:(id)target selector:(SEL)sel userInfo:(id)user
{
    if (!_commandForCurrentPatternRegistrations)
    {
        NSLog(@"AE: ERROR: registerNamedPattern called outside patternsForLang:inSystem: method!");
        return FALSE;
    }
    else if (!name || [name length] == 0)
    {
        NSLog(@"AE ERROR: Missing or empty name for registerNamedPattern!");
        return FALSE;
    }
    else if (!target)
    {
        NSLog(@"AE ERROR: No target specified for named pattern '%@'!", name);
        return FALSE;
    }
    else if (![target respondsToSelector:sel])
    {
        NSLog(@"AE ERROR: Named pattern '%@' registered with selector %s not available in target %p!", name, (const char*)sel, target);
        return FALSE;
    }
    else if (!sel)
    {
        NSLog(@"AE ERROR: No selector specified for named pattern '%@'!", name);
        return FALSE;
    }
    
    // find named pattern
    if (!_patternsPlist)
    {
        NSLog(@"AE ERROR: Attempt to register named pattern %@ but Patterns.plist is not loaded!", name);
        return FALSE;
    }
    NSDictionary* pttrns = [_patternsPlist objectForKey:@"patterns"];
    if (!pttrns)
    {
        NSLog(@"AE ERROR: Attempt to register named pattern %@ but Patterns.plist does not contain patterns array!", name);
        return FALSE;
    }
    NSDictionary* pttrn = [pttrns objectForKey:name];
    if (!pttrn)
    {
        NSLog(@"AE ERROR: Named pattern %@ not found in Patterns.plist!", name);
        return FALSE;
    }
    
    NSString* pattern = [pttrn objectForKey:@"pattern"];
    if (!pattern)
    {
        // try pattern array
        NSArray* patterns = [pttrn objectForKey:@"patterns"];
        if (!patterns)
        {
            NSLog(@"AE ERROR: Named pattern %@ does not have pattern or patterns key in Patterns.plist!", name);
            return FALSE;
        }
        else if ([patterns count] == 0)
        {
            NSLog(@"AE ERROR: Named pattern %@ has 0 strungs in patterns array in Patterns.plist!", name);
            return FALSE;
        }
        BOOL allOk = YES;
        for (NSString* xxx in patterns)
        {
            BOOL ok = [self registerPattern:xxx target:target selector:sel userInfo:user];
            if (!ok) allOk = NO;
        }
        return allOk;
    }
    
    // single pattern
    return [self registerPattern:pattern target:target selector:sel userInfo:user];
}
-(BOOL)registerNamedPattern:(NSString*)name target:(id)target selector:(SEL)sel
{
    return [self registerNamedPattern:name target:target selector:sel userInfo:nil];
}
-(BOOL)registerNamedPattern:(NSString*)name selector:(SEL)sel userInfo:(id)user
{
    return [self registerNamedPattern:name target:_commandForCurrentPatternRegistrations selector:sel userInfo:nil];
}
-(BOOL)registerNamedPattern:(NSString*)name selector:(SEL)sel
{
    return [self registerNamedPattern:name selector:sel userInfo:nil];
}
-(BOOL)registerNamedPattern:(NSString*)name userInfo:(id)user
{
    return [self registerNamedPattern:name selector:@selector(handlePatternMatch:context:) userInfo:user];
}
-(BOOL)registerNamedPattern:(NSString*)name
{
    return [self registerNamedPattern:name userInfo:nil];
}
//----------
// CONCRETE IMPLEMENTATION
-(BOOL)registerAllNamedPatternsForTarget:(id)target selector:(SEL)sel userInfo:(id)user
{
    if (!_commandForCurrentPatternRegistrations)
    {
        NSLog(@"AE: ERROR: registerAllNamedPatternsForTarget called outside patternsForLang:inSystem: method!");
        return FALSE;
    }
    
    if (!_patternsPlist)
    {
        NSLog(@"AE ERROR: Attempt to register all named patterns but Patterns.plist is not loaded!");
        return FALSE;
    }
    NSDictionary* pttrns = [_patternsPlist objectForKey:@"patterns"];
    if (!pttrns)
    {
        NSLog(@"AE ERROR: Attempt to register all named patterns but Patterns.plist does not contain patterns array!");
        return FALSE;
    }
    
    BOOL allOk = TRUE;
    
    for (NSString* patternKey in pttrns)
    {
        NSDictionary* pttrn = [pttrns objectForKey:patternKey];
        
        NSString* pattern = [pttrn objectForKey:@"pattern"];
        if (!pattern)
        {
            // try pattern array
            NSArray* patterns = [pttrn objectForKey:@"patterns"];
            if (!patterns)
            {
                NSLog(@"AE ERROR: Named pattern %@ does not have pattern or patterns key in Patterns.plist!", patternKey);
                return FALSE;
            }
            else if ([patterns count] == 0)
            {
                NSLog(@"AE ERROR: Named pattern %@ has 0 strungs in patterns array in Patterns.plist!", patternKey);
                return FALSE;
            }
            BOOL allOk = YES;
            for (NSString* xxx in patterns)
            {
                BOOL ok = [self registerPattern:xxx target:target selector:sel userInfo:user];
                if (!ok) allOk = NO;
            }
            return allOk;
        }
        else 
        {
            // single pattern
            BOOL ok = [self registerPattern:pattern target:target selector:sel userInfo:user];
            if (!ok) allOk = NO;
        }
    }
    
    return allOk;
}
-(BOOL)registerAllNamedPatternsForTarget:(id)target selector:(SEL)sel
{
    return [self registerAllNamedPatternsForTarget:target selector:sel userInfo:nil];
}
-(BOOL)registerAllNamedPatternsForSelector:(SEL)sel userInfo:(id)user
{
    return [self registerAllNamedPatternsForTarget:_commandForCurrentPatternRegistrations selector:sel userInfo:user];
}
-(BOOL)registerAllNamedPatternsForSelector:(SEL)sel
{
    return [self registerAllNamedPatternsForSelector:sel userInfo:nil];
}
-(BOOL)registerAllNamedPatternsWithUserInfo:(id)user
{
    return [self registerAllNamedPatternsForSelector:@selector(handlePatternMatch:context:) userInfo:user];
}
-(BOOL)registerAllNamedPatterns
{
    return [self registerAllNamedPatternsWithUserInfo:nil];
}
//----------
-(NSDictionary*)patternsPlist
{
    return _patternsPlist;
}

@end

#pragma mark - SIRI COMMANDS -----------------------------------------------------------------------------------

static NSObject<SECommand>* s_exclusiveCommand = nil;

void AEExtensionBeginExclusive(NSObject<SECommand>* ex)
{
    [s_exclusiveCommand autorelease];
    s_exclusiveCommand = [ex retain];
}
void AEExtensionEndExclusive()
{
    [s_exclusiveCommand release];
    s_exclusiveCommand = nil;
}

BOOL HandleSpeechExtensions(NSString* refId, NSString* text, NSArray* tokens, NSSet* tokenset)
{
    AEContext* ctx = [AEContext contextWithRefId:refId];
    
    // if we have exclusive mode, use it
    if (s_exclusiveCommand)
        return [s_exclusiveCommand handleSpeech:text tokens:tokens tokenSet:tokenset context:ctx];
    
    // go through all extensions
    NSArray* allEx = [AEExtension allExtensions];
    NSObject<SECommand>* cmd = nil;
    for (AEExtension* ex in allEx)
    {
        if ( [ex enabled] && (cmd = [ex handleSpeech:text tokens:tokens tokenSet:tokenset context:ctx]) )
        {
            [ctx setObject:cmd];
            return YES;
        }
    }
    
    return NO;
}


#pragma mark - SIRI SNIPPET ---------------------------------------------------------------------------------


@implementation SAK3AExtensionSnippet

-(id)init {
    //NSLog(@">> SAK3AExtensionSnippet init");
    if ( (self = [super init]) )
    {
        
    }
    return self;
}

- (id)encodedClassName
{
    return @"Snippet";
}
- (id)groupIdentifier
{
    return @"me.k3a.ace.extension";
}

@end
// ------------------
@implementation K3AExtensionSnippetController

- (id)view
{
    //NSLog(@">> K3AExtensionSnippetController view");
    return _view;
}

- (void)dealloc
{
    //NSLog(@">> K3AExtensionSnippetController dealloc");
    [super dealloc];
    [_view release];
    [_snip release];
}

-(id)init
{
    //NSLog(@">> K3AExtensionSnippetController Init");
    return [super init];
}

- (id)initWithAceObject:(id)ace delegate:(id)dlg
{
    //NSLog(@">> K3AExtensionSnippetController initWithAceObject: Properties: %@", [ace properties]);
    
    if ( (self = [super initWithAceObject:ace delegate:dlg]) )
    {
        if (![ace isKindOfClass:[SAK3AExtensionSnippet class]])
        {
            NSLog(@"AE ERROR: Wrong class received (got %s, expected SAK3AExtensionSnippet)", object_getClassName(ace));
            [self release];
            return nil;
        }
        
        NSString* snipClass = [[ace properties] objectForKey:@"snippetClass"];
        NSDictionary* snipProps = [[ace properties] objectForKey:@"snippetProps"];
        if (!snipProps) snipProps = [NSDictionary dictionary];
        
        if (!snipClass || [snipClass length] < 2)
        {
            NSLog(@"AE ERROR: Snippet class not specified!");
            [self release];
            return nil;
        }
        
        for (AEExtension* ex in [AEExtension allExtensions])
        {
            _snip = [ex allocSnippet:snipClass properties:snipProps];
            if (_snip) break;
        }
        
        if (!_snip)
        {
            NSLog(@"AE ERROR: Snippet class %@ could not be found in any loaded extension bundle!", snipClass);
            [self release];
            return nil;
        }
        
        _view = [[_snip view] retain];
    }
    return self;
}

@end



