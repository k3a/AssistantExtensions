//
//  AESupport.mm
//  SiriCommands
//
//  Created by Kexik on 1/22/12.
//  Copyright (c) 2012 K3A. All rights reserved.
//
#include "AESupport.h"
#include "shared.h"
#include "main.h"

# include <sys/types.h>
# include <sys/socket.h>
# include <sys/ioctl.h>
# include <netinet/in.h>
# include <netdb.h>
# include <pthread.h>
# include <sys/stat.h>
# include <stdlib.h>
# include <unistd.h>

#import <VoiceServices.h>

template <typename T>
inline const T& my_min(const T& a, const T& b)
{
    return a<b?a:b;
}


/// send to siri app
bool AESendToClient(NSDictionary* aceObject)
{
    if (InSpringBoard())
    {
        NSDictionary* resp = IPCCallResponse(@"me.k3a.AssistantExtensions.ad", @"Send2Client", 
                                             [NSDictionary dictionaryWithObject:aceObject forKey:@"object"]);
        return [[resp objectForKey:@"reply"] boolValue];
    }
    else
    {
        return SessionSendToClient(aceObject);
    }
}
/// send to apple siri server
bool AESendToServer(NSDictionary* aceObject)
{
    if (InSpringBoard())
    {
        NSDictionary* resp = IPCCallResponse(@"me.k3a.AssistantExtensions.ad", @"Send2Server", 
                                             [NSDictionary dictionaryWithObject:aceObject forKey:@"object"]);
        return [[resp objectForKey:@"reply"] boolValue];
    }
    else
    {
        return SessionSendToServer(aceObject);
    }
}

static VSSpeechSynthesizer* s_synth = nil;

void AESupportInit(bool springBoard)
{
    // init s_synth in assistantd process
    if (!springBoard)
    {
        s_synth = [[VSSpeechSynthesizer alloc] init];
        [s_synth setVoice:@"Samantha"];
        // TODO: set correct voice based on language
    }
}
void AESupportShutdown()
{
    [s_synth release];
    s_synth = nil;
}

void AESay(NSString* text, NSString* lang)
{
    // say using s_synth when in assistantd process or forward it from springboard
    if (!InSpringBoard())
    {
        //static Class _SBAssistantController = objc_getClass("SBAssistantController");
        //[(SBAssistantController*)[_SBAssistantController sharedInstance] _say:text];
        
        [s_synth startSpeakingString:text withLanguageCode:lang];
    }
    else
        IPCCall(@"me.k3a.AssistantExtensions.ad", @"Say", 
                        [NSDictionary dictionaryWithObjectsAndKeys:text,@"text",lang,@"lang", nil]);
}


NSString* AEGetSystemLanguage()
{
    NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
    /*NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
     NSArray* arrayLanguages = [userDefaults objectForKey:@"AppleLanguages"];
     NSString* language = [arrayLanguages objectAtIndex:0];*/
    
    char lang[16];
    strcpy(lang, [language UTF8String]);
    
    unsigned sepIdx = strlen(lang);
    bool afterSep = false;
    for (unsigned i=0; i<strlen(lang); i++)
    {
        if (lang[i] == '_' || lang[i] == '-')
        {
            lang[i] = '-';
            sepIdx = i;
            afterSep = true;
        }
        else if (afterSep)
            lang[i] = toupper(lang[i]);
    }
    
    return [NSString stringWithUTF8String:lang];
}

NSString* AEGetAssistantLanguage()
{
    NSDictionary* dict = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.apple.assistant.plist"];
    NSString* lang = [dict objectForKey:@"Session Language"];
    if (![lang length])
        return @"en-US";
    else
        return lang;
}













