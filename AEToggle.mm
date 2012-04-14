//
//  toggles.mm
//  AssistantExtensions
//
//  Created by K3A on 11/29/11.
//  Copyright (c) 2011 K3A. All rights reserved.
//
#include "AEToggle.h"
#include "main.h"

#import <dlfcn.h>
// directory listing
#include <sys/types.h>
#include <dirent.h>

#include "AESupport.h"
#include "AESpringBoardMsgCenter.h"
#import "AEStringAdditions.h"
#include "SiriObjects.h"

static NSMutableDictionary* s_toggleDict = nil;

const char* togglesPath = "/var/mobile/Library/SBSettings/Toggles/"; // slash must be at the end
const int togglesPathLen = strlen(togglesPath);

#pragma mark - TOGGLE CLASS

@implementation AEToggle

+(BOOL)initToggles
{
    s_toggleDict = [[NSMutableDictionary alloc] init];
    
    struct dirent *direntp = NULL;
    
    DIR *dirp = opendir(togglesPath);
    if (dirp == NULL)
    {
        NSLog(@"Error opening toggles dir %s. SBSettings not installed?", togglesPath);
        return FALSE;
    }
    
    NSLog(@"Loading SBSettings Toggles:");
    while ((direntp = readdir(dirp)) != NULL)
    {
        /* Ignore special directories. */
        if ((strcmp(direntp->d_name, ".") == 0) ||
            (strcmp(direntp->d_name, "..") == 0))
            continue;
        
        NSString* name = [NSString stringWithUTF8String:direntp->d_name];
        
        AEToggle* toggle = [AEToggle toggleWithName:name];
        if (toggle) [s_toggleDict setObject:toggle forKey:[name lowercaseString]];
    }
    
    /* Finalize resources. */
    closedir(dirp);    
    return TRUE;
}

+(void)shutdownToggles
{
    [s_toggleDict release];
}

+(NSArray*)allToggleNames
{
    return [s_toggleDict allKeys];
}

+(id)findToggleNamed:(NSString*)name
{
    float bestScore = 0;
    AEToggle* bestToggle = nil;
    
    for (NSString* dictName in [s_toggleDict allKeys])
    {
        float score = [name similarityWithString:dictName];
        if (score > bestScore)
        {
            bestScore = score;
            bestToggle = [s_toggleDict objectForKey:dictName];
            if (score == 1.0f) break; // exact match
        }
    }
    
    if (bestScore < 0.57f) return nil; // too low score
    
    return bestToggle;
}

+(id)toggleWithName:(NSString*)name
{
    return [[[AEToggle alloc] initWithName:name] autorelease];
}

-(id)initWithName:(NSString*)name
{
    if ( (self = [super init]) )
    {
        char full_name[_POSIX_PATH_MAX + 1];
        if ((togglesPathLen + strlen([name UTF8String]) + 1) > _POSIX_PATH_MAX)
        {
            [self release];
            return nil;
        }
        
        strcpy(full_name, togglesPath);
        strcat(full_name, [name UTF8String]);
        strcat(full_name, "/Toggle.dylib");
        
        struct stat fstat;
        if (stat(full_name, &fstat) < 0)
        {
            NSLog(@"Toggle at path %s cannot be found!", full_name);
            [self release];
            return nil;
        }
        
        _dylib = dlopen(full_name, RTLD_LAZY);
        if (!_dylib)
        {
            NSLog(@"Failed to open toggle %@ (%s)!", name, full_name);
            [self release];
            return nil;
        }
        dlerror();
        
        _isCapable = (BoolFn)dlsym(_dylib, "isCapable");
        const char *dlsym_error = dlerror();
        if (!_isCapable)
        {
            NSLog(@"Error while loading %@ toggle: %s!", name, dlsym_error);
            dlclose(_dylib);
            [self release];
            return nil;
        }
        
        //bool capable = _isCapable();
        //NSLog(@"Toggle %@, capable: %s\n", name, capable?"YES":"NO");
        
        /*if (!capable)
        {
            dlclose(_dylib);
            [self release];
            return nil;
        }*/
        
        _setState = (VoidBoolFn)dlsym(_dylib, "setState");
        dlsym_error = dlerror();
        if (!_setState)
        {
            NSLog(@"Error while loading %@ toggle: %s!", name, dlsym_error);
            dlclose(_dylib);
            [self release];
            return nil;
        }
        
        _isEnabled = (BoolFn)dlsym(_dylib, "isEnabled");
        dlsym_error = dlerror();
        if (!_isEnabled)
        {
            NSLog(@"Error while loading %@ toggle: %s!", name, dlsym_error);
            dlclose(_dylib);
            [self release];
            return nil;
        }
    
        _getStateFast = (BoolFn)dlsym(_dylib, "getStateFast");
        
        //BoolFn bpInit = (BoolFn)dlsym(_dylib, "BossPrefsInit");
        //if (bpInit) bpInit();
        
        _speakableName = [name copy];
    }
    
    return self;
}

-(void)dealloc
{
    dlclose(_dylib);
    [_speakableName release];
    [super dealloc];
}

-(BOOL)state
{
    /*if (_getStateFast) 
        return _getStateFast();
    else*/
        return _isEnabled()?YES:NO;
}
-(BOOL)isCapable
{
    return _isCapable();
}
-(void)setState:(BOOL)state
{
    _setState(state);
}

-(NSString*)speakableName
{
    return _speakableName;
}

@end


#pragma mark - SIRI COMMANDS

bool HandleSpeechToggles(NSString* refId, NSString* text, NSArray* tokens, NSSet* tokenset)
{
    if ([tokenset containsObject:@"alarm"] || [tokenset containsObject:@"alarms"]) return false; // do not break turn off alarms
    
    if ([tokens count]>2 && [[tokens objectAtIndex:0] isEqualToString:@"turn"])
    {
        NSString* text = @"";
        int tokNum = [tokens count];
        
        if ([[tokens objectAtIndex:1] isEqualToString:@"on"])
        {
            NSMutableString* tog = [NSMutableString string];
            for (int i=2; i<tokNum; i++)
            {
                if (i == tokNum-1)
                    [tog appendString:[tokens objectAtIndex:i]];
                else
                    [tog appendFormat:@"%@ ", [tokens objectAtIndex:i]];
            }
            // mywi fix
            if ([tog isEqualToString:@"my wife"]) tog = [NSMutableString stringWithString:@"mywi"];
            // '3 g' fix
            else if ([tog isEqualToString:@"3 g"]) tog = [NSMutableString stringWithString:@"3g"];
            
            NSLog(@"===> ACTION: Turn on toggle %@", tog);
            
            AEToggle* togObj = [AEToggle findToggleNamed:tog];
            if (togObj == nil)
                text = [NSString stringWithFormat:@"Sorry, toggle %@ is not installed.", [tog stringWithFirstUppercase]];
            else
            {
                [togObj setState:YES];
                text = [NSString stringWithFormat:@"%@ has been turned on.", [tog stringWithFirstUppercase]];
            }
        }
        else
        {
            NSMutableString* tog = [NSMutableString string];
            for (int i=2; i<tokNum; i++)
            {
                if (i == tokNum-1)
                    [tog appendString:[tokens objectAtIndex:i]];
                else
                    [tog appendFormat:@"%@ ", [tokens objectAtIndex:i]];
            }
            // mywi fix
            if ([tog isEqualToString:@"my wife"]) tog = [NSMutableString stringWithString:@"mywi"];
            // '3 g' fix
            else if ([tog isEqualToString:@"3 g"]) tog = [NSMutableString stringWithString:@"3g"];
            
            NSLog(@"===> ACTION: Turn off toggle %@", tog);
            
            AEToggle* togObj = [AEToggle findToggleNamed:tog];
            if (togObj == nil)
                text = [NSString stringWithFormat:@"Sorry, toggle %@ is not installed.", [tog stringWithFirstUppercase]];
            else
            {
                [togObj setState:NO];
                text = [NSString stringWithFormat:@"%@ has been turned off.", [tog stringWithFirstUppercase]];
            }
        }
        
        AESendToClient(SOCreateAceAddViewsUtteranceView(refId, text, text));
        AESendToClient(SOCreateAceRequestCompleted(refId));
        
        return true;
    }
    else if ([tokens count]>1 
             && 
             ([[tokens objectAtIndex:0] isEqualToString:@"list"] || [[tokens objectAtIndex:0] isEqualToString:@"least"])
             &&
             ([tokenset containsObject:@"cheese"] || [tokenset containsObject:@"switches"] || [tokenset containsObject:@"toggles"] || [tokenset containsObject:@"speeches"] || [tokenset containsObject:@"seachase"]) 
             )
    {
        NSLog(@"===> ACTION: List of switches.");
        
        NSMutableString* strSpeak = [NSMutableString stringWithString:@"Toggles available:\n"];
        NSMutableString* str = [NSMutableString stringWithString:@"Toggles available:\n"];
        
        for (NSString* tname in [AEToggle allToggleNames])
        {
            AEToggle* togObj = [AEToggle findToggleNamed:tname];
            if (togObj)
            {
                NSString* tnameUpper = [tname stringWithFirstUppercase];
                
                [str appendFormat:@"%@: %s\n", tnameUpper, [togObj state]?"Enabled":"Disabled"];
                [strSpeak appendFormat:@"%@: %s @{tts#\e\\pause=100\\}\n", tnameUpper, [togObj state]?"Enabled":"Disabled"];
            }
        }
        
        AESendToClient(SOCreateAceAddViewsUtteranceView(refId, str, strSpeak));
        AESendToClient(SOCreateAceRequestCompleted(refId));
        
        return true;
    }
    
    return false;
}











