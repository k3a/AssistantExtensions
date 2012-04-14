//
//  systemcmds.m
//  objcdump
//
//  Created by Kexik on 11/29/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
#include "systemcmds.h"
#import "AEStringAdditions.h"
#import "AESpringBoardMsgCenter.h"
#import "OS5Additions.h"

#import <objc/runtime.h>
#include <substrate.h>
#include "main.h"
#include "AESupport.h"
#include "SiriObjects.h"
#import "AEExtension.h"

#import <Twitter/Twitter.h>
#import <Accounts/Accounts.h>

#define UIApp [UIApplication sharedApplication]

//static NSMutableArray *s_displayStacks = nil;

// Display stack names
#define SBWPreActivateDisplayStack        [s_displayStacks objectAtIndex:0]
#define SBWActiveDisplayStack             [s_displayStacks objectAtIndex:1]
#define SBWSuspendingDisplayStack         [s_displayStacks objectAtIndex:2]
#define SBWSuspendedEventOnlyDisplayStack [s_displayStacks objectAtIndex:3]

/*HOOK(SBDisplayStack, init, id)
{
    id stack = ORIG();
    [s_displayStacks addObject:stack];
    return stack;
}
END

HOOK(SBDisplayStack, dealloc, void)
{
    [s_displayStacks removeObject:self];
    CALL_ORIG();
}
END*/

UIViewController *s_twitterController = nil;
HOOK(SBAssistantController, viewWillDisappear, void)
{
    //theiostream, please, remove logs like this after you are done :P
    //NSLog(@"ON VIEWDIDDISAPPEAR");
    
    if (s_twitterController)
    {
        NSLog(@"AE: Assistant dismissed, dismissing tweet controller.");
        [s_twitterController dismissModalViewControllerAnimated:NO];
        [s_twitterController release];
        s_twitterController = nil;
    }
    else
        NSLog(@"AE: Assistant dismissed.");
    
    // inform springboard center
    SBCenterAssistantDismissed();
    
    // tell each extension the assistant is dismissed
    for (AEExtension* ex in [AEExtension allExtensions])
        [ex callAssistantDismissed];
}
END


bool InitSystemCmds()
{
    // display stacks
    /*s_displayStacks = [[NSMutableArray alloc] initWithCapacity:5];
    
    // init display stack hooks
    GET_CLASS(SBDisplayStack)
    LOAD_HOOK(SBDisplayStack, init, init)
    LOAD_HOOK(SBDisplayStack, dealloc, dealloc)*/
    
    GET_CLASS(SBAssistantController)
    LOAD_HOOK(SBAssistantController, viewWillDisappear, viewWillDisappear)
    
    return true;
}

#if 0

void ShutdownSystemCmds()
{
    [s_displayStacks release];
}

//TODO: remove unnecesary CPDistributedMessagingCenter calls (we are now in springboard on both sides)

static BOOL LaunchApp(id app)
{
    //SBApplication* app = [tim userInfo];
    
    // --- unlock device
    static SBAwayController* awayController = [objc_getClass("SBAwayController") sharedAwayController];
    if ([awayController respondsToSelector:@selector(_unlockWithSound:isAutoUnlock:)])
     {
     [awayController _unlockWithSound:NO isAutoUnlock:YES];
     }
    if ((bool)[awayController isDeviceLocked] && (bool)[awayController isPasswordProtected])
    {
        //[awayController applicationRequestedDeviceUnlock];
        return FALSE;
    }
    else
        [awayController _unlockWithSound:NO isAutoUnlock:YES];
    [[awayController awayView] hideBulletinView];
    
    // --- launch the app
    
    id fromApp = [SBWActiveDisplayStack topApplication];
    //NSString *fromIdent = fromApp ? [fromApp displayIdentifier] : @"com.apple.springboard";
    
    if ([fromIdent isEqualToString:@"com.apple.springboard"]) {
     // Switching from SpringBoard; simply activate the target app
     [app setDisplaySetting:0x4 flag:YES]; // animate
     
     // Activate the target application
     [SBWPreActivateDisplayStack pushDisplay:app];
     } else {
    // -- activate the other app
    
    // Switching to another app; setup app-to-app
    [app setActivationSetting:0x40 flag:YES]; // animateOthersSuspension
    [app setActivationSetting:0x20000 flag:YES]; // appToApp
    [app setDisplaySetting:0x4 flag:YES]; // animate
    
    // Activate the target application (will wait for deactivation of current app)
    [SBWPreActivateDisplayStack pushDisplay:app];
    
    // -- Deactivate the current application
    
    // NOTE: Must set animation flag for deactivation, otherwise
    //       application window does not disappear (reason yet unknown)
    [fromApp setDeactivationSetting:0x2 flag:YES]; // animate
    
    // Deactivate by moving from active stack to suspending stack
    [SBWActiveDisplayStack popDisplay:fromApp];
    [SBWSuspendingDisplayStack pushDisplay:fromApp];
    }
    
    // --- dismiss assistant
    static Class _SBAssistantController = objc_getClass("SBAssistantController");
    [(SBAssistantController*)[_SBAssistantController sharedInstance] dismissAssistant];
    
    return TRUE;
}

static void SendTweet(NSString* text)
{
    if ([TWTweetComposeViewController canSendTweet]) 
    {
        // Create account store, followed by a twitter account identifier
        // At this point, twitter is the only account type available
        ACAccountStore *account = [[ACAccountStore alloc] init];
        ACAccountType *accountType = [account accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
        
        // Request access from the user to access their Twitter account
        [account requestAccessToAccountsWithType:accountType withCompletionHandler:^(BOOL granted, NSError *error) 
         {
             // Did user allow us access?
             if (granted == YES)
             {
                 // Populate array with all available Twitter accounts
                 NSArray *arrayOfAccounts = [account accountsWithAccountType:accountType];
                 
                 // Sanity check
                 if ([arrayOfAccounts count] > 0) 
                 {
                     // Keep it simple, use the first account available
                     ACAccount *acct = [arrayOfAccounts objectAtIndex:0];
                     
                     // Build a twitter request
                     TWRequest *postRequest = [[TWRequest alloc] initWithURL:
                                               [NSURL URLWithString:@"http://api.twitter.com/1/statuses/update.json"] 
                                                                  parameters:[NSDictionary dictionaryWithObject:text 
                                                                                                         forKey:@"status"] 
                                                               requestMethod:TWRequestMethodPOST];
                     
                     // Post the request
                     [postRequest setAccount:acct];
                     
                     // Block handler to manage the response
                     [postRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) 
                      {
                          NSLog(@"AE: Twitter response, HTTP response: %i", [urlResponse statusCode]);
                      }];
                 }
                 else
                 {
                     NSLog(@"AE: You don't have twitter account configured in Settings!");
                 }
             }
         }];
    }
}

void GSEventSetBacklightLevel(float level);

bool HandleSpeechSystemCmds(NSString* refId, NSString* text, NSArray* tokens, NSSet* tokenset)
{
    if ([tokenset containsObject:@"restart"] && [tokenset containsObject:@"springboard"])
    {
        NSLog(@"==> ACTION: Respring");
        AESendToClient(SOCreateAceAddViewsUtteranceView(refId, @"OK"));
        AESendToClient(SOCreateAceRequestCompleted(refId));
        
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(queue, ^{
            usleep(600000);
            system("killall SpringBoard");
        });
        return true;
    }
    else if ([tokens count] == 1 && [tokenset containsObject:@"reboot"])
    {
        NSLog(@"==> ACTION: Reboot");
        [(SpringBoard*)UIApp reboot];
    }
    else if (  ([tokens count] == 1 && [tokenset containsObject:@"shutdown"])
             ||([tokens count] == 2 && [[tokens objectAtIndex:0] isEqualToString:@"power"] &&
                 ([[tokens objectAtIndex:1] isEqualToString:@"off"]||[[tokens objectAtIndex:1] isEqualToString:@"down"]) )  )
    {
        NSLog(@"==> ACTION: Shutdown");
        [(SpringBoard*)UIApp powerDown];
    }
    else if ([tokens count] == 3 &&
             ([[tokens objectAtIndex:0] isEqualToString:@"kill"]||[[tokens objectAtIndex:0] isEqualToString:@"close"])
             && [[tokens objectAtIndex:1] isEqualToString:@"all"] && [[tokens objectAtIndex:2] isEqualToString:@"applications"] )
    {
        NSLog(@"==> ACTION: Kill all applications");
        
        static Class _SBApplicationController = objc_getClass("SBApplicationController");
        id appController = [_SBApplicationController sharedInstance];
        static Class _SBAppSwitcherController = objc_getClass("SBAppSwitcherController");
        id appSwitcher = [_SBAppSwitcherController sharedInstance];
        
        for (id appObj in [appController allApplications])
        {
            [appObj kill];
            [appSwitcher _removeApplicationFromRecents:appObj];
        }
        
        AESendToClient(SOCreateAceAddViewsUtteranceView(refId, @"All applications have been closed."));
        AESendToClient(SOCreateAceRequestCompleted(refId));
        
        return true;
    }
    else if ([tokenset containsObject:@"reload"] && [tokenset containsObject:@"extensions"])
    {
        NSLog(@"==> ACTION: Reload extensions");
        
        AESendToClient(SOCreateAceAddViewsUtteranceView(refId, @"Reloading extensions..."));
        
        [AEExtension reloadExtensions];
        
        AESendToClient(SOCreateAceAddViewsUtteranceView(refId, @"Extensions has been reloaded."));
        AESendToClient(SOCreateAceRequestCompleted(refId));
        
        return true;
    }
    else if (([tokenset containsObject:@"brightness"] || [tokenset containsObject:@"backlight"]))
    {
        float val = 0;
        
        for (NSString* tok in tokens)
        {
            int ival = [tok intValue];
            if (ival > 0) 
            {
                val = ival/100.0f;
                break;
            }
        }
        
        if (val == 0) return true; // bad value
        
        NSLog(@"==> ACTION: Set brightness: %.2f", val);
        
        AESendToClient(SOCreateAceAddViewsUtteranceView(refId, @"As you wish."));
        AESendToClient(SOCreateAceRequestCompleted(refId));
        
        if (val < 0.01f) val = 0.01f;
        if (val > 1.0f) val = 1.0f;
        
        UIApplication* TheApp = [UIApplication sharedApplication];
         [TheApp setBacklightLevel:val permanently:YES];
        //GSEventSetBacklightLevel(val);
		static Class _SBBrightnessController = objc_getClass("SBBrightnessController");
		[[_SBBrightnessController sharedBrightnessController] setBrightnessLevel:val];
        return true;
    }
    else if ([tokens count]>1 && ([[tokens objectAtIndex:0] isEqualToString:@"say"] || [[tokens objectAtIndex:0] isEqualToString:@"repeat"])  )
    {
        NSMutableString* str = [NSMutableString string];
        
        for (unsigned i=1; i<[tokens count]; i++)
            [str appendFormat:@"%@ ", [tokens objectAtIndex:i]];
            
        NSLog(@"==> ACTION: Say '%@'", str);
        AESendToClient(SOCreateAceAddViewsUtteranceView(refId, str));
        AESendToClient(SOCreateAceRequestCompleted(refId));
        return true;
    }
    else if ( [tokenset containsObject:@"tweet"] || [tokenset containsObject:@"tweets"] )
    {
        NSMutableString* tweetText = [NSMutableString string];
        
        bool usingTweetAndSend = true;
        bool legitCommand = false;
        // just show a dialog 
        if ([tokenset count] == 1 || ([tokenset count] == 2 && [[tokens objectAtIndex:0] isEqualToString:@"show"])) 
        {
            usingTweetAndSend = false;
            legitCommand = true;
        }
        else
        {
            bool tweetAndSendPossible = [tokens count]>2;
            for (unsigned tid = 0; tid < [tokens count]; tid++)
            {
                if ( tid == 0 && tweetAndSendPossible && ([[tokens objectAtIndex:0] isEqualToString:@"show"]||[[tokens objectAtIndex:0] isEqualToString:@"display"]) && ([[tokens objectAtIndex:1] isEqualToString:@"tweet"] || [[tokens objectAtIndex:1] isEqualToString:@"tweets"]) )
                { // show tweet
                    usingTweetAndSend = false;
                    [tweetText appendFormat:@"%@ ",[[tokens objectAtIndex:2] stringWithFirstUppercase]];
                    tid += 2;
                    legitCommand = true;
                    continue;
                }
                else if ( tid == 0 && ( [[tokens objectAtIndex:0] isEqualToString:@"tweet"] || [[tokens objectAtIndex:0] isEqualToString:@"tweets"] ) )
                {
                    usingTweetAndSend = true;
                    [tweetText appendFormat:@"%@ ",[[tokens objectAtIndex:1] stringWithFirstUppercase]];
                    tid += 1;
                    legitCommand = true;
                    continue;
                }
                else if (tid < [tokens count]-1)
                    [tweetText appendFormat:@"%@ ", [tokens objectAtIndex:tid]];
                else
                    [tweetText appendString:[tokens objectAtIndex:tid]];
            }
        }
        
        if (!legitCommand)
        {
            NSLog(@"AE: Found tweet word, but probably not tweet command");
            return false;
        }
        
        if (usingTweetAndSend)
            NSLog(@"==> ACTION: Tweet and send: '%@'", tweetText);
        else
            NSLog(@"==> ACTION: Tweet: '%@'", tweetText);
        
        
        if (usingTweetAndSend)
            SendTweet(tweetText);
        else 
        {
            if (s_twitterController) // tweet dialog already shown
            {
                AESendToClient(SOCreateAceRequestCompleted(refId));
                return true; 
            }
            
            Class SBAssistantController = objc_getClass("SBAssistantController");
            id assistCtrl = [SBAssistantController sharedInstance];
            if (!assistCtrl) return nil;
            
            s_twitterController = [[UIViewController alloc] init]; // TODO memory
            s_twitterController.view = [assistCtrl view];
            
            TWTweetComposeViewController* twitter = [[TWTweetComposeViewController alloc] init];
            [twitter setInitialText:tweetText];
            twitter.completionHandler = ^(TWTweetComposeViewControllerResult res) 
            {
                if(res == TWTweetComposeViewControllerResultDone)
                {
                }
                else if(res == TWTweetComposeViewControllerResultCancelled)
                {
                }
                
                NSLog(@"AE: Tweet composer done.");
                static Class _SBUIController = objc_getClass("SBUIController");
                [(SBUIController*)[_SBUIController sharedInstance] _hideKeyboard];
                
                [s_twitterController dismissModalViewControllerAnimated:YES];
                [s_twitterController release];
                s_twitterController = nil;
            };
            
            [s_twitterController presentViewController:twitter animated:YES completion:nil];
        }
        
        if (usingTweetAndSend)
            AESendToClient(SOCreateAceAddViewsUtteranceView(refId, [NSString stringWithFormat:@"Sent tweet: %@", tweetText]));
        else
            AESendToClient(SOCreateAceAddViewsUtteranceView(refId, @"Ok, here is your tweet."));
        
        AESendToClient(SOCreateAceRequestCompleted(refId));
        return true;
    }
    else if (
             ([tokens count]==2 && [[tokens objectAtIndex:0] isEqualToString:@"lock"] && ([[tokens objectAtIndex:1] isEqualToString:@"screen"] || [[tokens objectAtIndex:1] isEqualToString:@"phone"]))
           || ([tokens count]==1 && [tokenset containsObject:@"lockscreen"])  
             )
    {
        AESendToClient(SOCreateAceAddViewsUtteranceView(refId, @"Locked."));
        AESendToClient(SOCreateAceRequestCompleted(refId));
        
        Class _SBUIController = objc_getClass("SBUIController");
        SBUIController* controller = (SBUIController*)[_SBUIController sharedInstance];
        
        if ([controller respondsToSelector:@selector(lock)])
            [controller lock];
        if ([controller respondsToSelector:@selector(lockFromSource:)])
            [controller lockFromSource:0];
        //[controller wakeUp:nil];
        
        return true;
    }
    else if ([tokens count]>1)
    {
        NSString* firstToken = [tokens objectAtIndex:0];
        
        if ([firstToken isEqualToString:@"should"] && [[tokens objectAtIndex:1] isEqualToString:@"i"])
        {
            NSLog(@"==> ACTION: Should I...?");
            bool yes = rand() % 100 < 50;
            AESendToClient(SOCreateAceAddViewsUtteranceView(refId, yes?@"Yes":@"No"));
            AESendToClient(SOCreateAceRequestCompleted(refId));
            return true;
        }
        else if ([firstToken isEqualToString:@"generate"] && [tokenset containsObject:@"random"])
        {
            NSLog(@"==> ACTION: A random number");
            int i = rand() % 101;
            AESendToClient(SOCreateAceAddViewsUtteranceView(refId, [NSString stringWithFormat:@"%d", i]));
            AESendToClient(SOCreateAceRequestCompleted(refId));
            return true;
        }
        else if ( ([firstToken isEqualToString:@"open"] || [firstToken isEqualToString:@"launch"]) )
        {
            NSMutableString* app = [NSMutableString string]; //[[tokens lastObject] lowercaseString];
            for (unsigned tid = 1; tid < [tokens count]; tid++)
            {
                if (tid < [tokens count]-1)
                    [app appendFormat:@"%@ ", [tokens objectAtIndex:tid]];
                else
                    [app appendString:[tokens objectAtIndex:tid]];
            }
            
            NSLog(@"==> ACTION: Launch app '%@'", app);
            
            NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:app,@"app", nil];
            NSString* reply = [[[CPDistributedMessagingCenter centerNamed:@"me.k3a.AssistantExtensions"] sendMessageAndReceiveReplyName:@"LaunchApp" userInfo:params] objectForKey:@"reply"];
            
            if (!app) return false;
            
            if ([app isEqualToString:@"nava gone"] || [app isEqualToString:@"navvy gone"])
                [app setString:@"Navigon"];
            
            float bestScore = 0;
            id bestApp = nil;
            
            static Class _SBApplicationController = objc_getClass("SBApplicationController");
            id appController = [_SBApplicationController sharedInstance];
            for (id appObj in [appController allApplications])
            {
                float score = [app similarityWithString:[appObj displayName]];
                if (score > bestScore)
                {
                    bestScore = score;
                    bestApp = appObj;
                    if (score == 1.0f) break; // exact match
                }
            }
            
            NSLog(@"Lauch best match %@ (score %.2f)", [bestApp displayName], bestScore);
            if (bestApp && bestScore > 0.57f)
            {
                NSLog(@"Launching %@ (%@)...", [bestApp displayName], [bestApp displayIdentifier]);
                
                //[NSTimer scheduledTimerWithTimeInterval:1.5f target:self selector:@selector(launchApp:) userInfo:app repeats:NO];
                if (LaunchApp(bestApp))
                {
                    AESay([NSString stringWithFormat:@"Launching %@", [app stringWithFirstUppercase]]);
                }
                else
                {
                    AESendToClient(SOCreateAceAddViewsUtteranceView(refId, @"Sorry, I don't know your lockscreen password."));
                }
            }
            else
            {
                AESendToClient(SOCreateAceAddViewsUtteranceView(refId, [NSString stringWithFormat:@"Sorry, application %@ is not installed.", [app stringWithFirstUppercase]]));
            }
            
            AESendToClient(SOCreateAceRequestCompleted(refId));
            return true;
        }
        else if ([firstToken isEqualToString:@"battery"] && [tokenset containsObject:@"level"])
        {
            NSLog(@"==> ACTION: Battery level");
            
            static Class _SBUIController = objc_getClass("SBUIController");
            if (!_SBUIController) return false;
            
            int perc = (int)[(SBUIController*)[_SBUIController sharedInstance] curvedBatteryCapacityAsPercentage];
            
            AESendToClient(SOCreateAceAddViewsUtteranceView(refId, [NSString stringWithFormat:@"Battery at %d %%.", perc]));
            
            AESendToClient(SOCreateAceRequestCompleted(refId));
            return true;
        }
    }
    
    return false;
}

#endif
