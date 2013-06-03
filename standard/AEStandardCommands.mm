#import "AEStandardCommands.h"
#import "../AEStringAdditions.h"

#import <objc/runtime.h>
#import <objc/message.h>
#import <LibDisplay.h>
#import <Twitter/Twitter.h>
#import <SpringBoard/SpringBoard-Class.h>
#import <SpringBoard/SBIcon.h>
#import <SpringBoard/SBUIController.h>
#import <SpringBoard/SBAwayController.h>
#import <Accounts/Accounts.h>

@protocol SBDeviceLockController
-(BOOL)isBlockedForThermalCondition;
-(BOOL)isDeviceLockedOrBlocked;
-(BOOL)isDeviceLocked;
-(BOOL)isPasswordProtected;
@end

static id AEApplicationForDisplayName(NSString *displayName) {
	NSArray *apps = [[objc_getClass("SBApplicationController") sharedInstance] allApplications];

	float bestScore = 0;
    id bestApp = nil;

	for (id app in apps) 
	{
		float score = [displayName similarityWithString:[app displayName]];
        if (score > bestScore)
        {
       		bestScore = score;
    		bestApp = app;
           	if (score == 1.0f) break; // exact match
        }
	}

	//if (bestScore < 1.0f) NSLog(@"AE Standard: App best match %@ (score %.2f)", [bestApp displayName], bestScore);
   
	if (bestApp && bestScore > 0.57f)
		return bestApp;
	else
		return nil;
}

BOOL error = NO;
static BOOL AESendTweet(NSString *text) {
	if ([TWTweetComposeViewController canSendTweet]) {
		ACAccountStore *account = [[ACAccountStore alloc] init];
		ACAccountType *accountType = [account accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
		
		[account requestAccessToAccountsWithType:accountType withCompletionHandler:^(BOOL granted, NSError *e) {
			if (granted) {
				NSArray *arrayOfAccounts = [account accountsWithAccountType:accountType];
				if ([arrayOfAccounts count] > 0) {
					ACAccount *acct = [arrayOfAccounts objectAtIndex:0];
					
					NSDictionary *param = [NSDictionary dictionaryWithObject:text forKey:@"status"];
					TWRequest *postRequest = [[TWRequest alloc] initWithURL:[NSURL URLWithString:@"http://api.twitter.com/1/statuses/update.json"] parameters:param requestMethod:TWRequestMethodPOST];
					[postRequest setAccount:acct];
					[postRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *e) {
						if ([urlResponse statusCode] != 200)
							error = YES;
					}];
				}
				else
					error = YES;
			}
		}];
	}
	else
		error = YES;
		
	return !error;
}

TWTweetComposeViewController* s_twitterController = nil;

static BOOL AEPreviewTweet(NSString* tweetText)
{
    if (s_twitterController) // tweet dialog already shown
    {
        return YES; 
    }
    
    Class SBAssistantController = objc_getClass("SBAssistantController");
    id assistCtrl = [SBAssistantController sharedInstance];
    if (!assistCtrl) return NO;
    
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
        
        NSLog(@"AE Standard: Tweet composer done.");
        static Class _SBUIController = objc_getClass("SBUIController");
        [(SBUIController*)[_SBUIController sharedInstance] _hideKeyboard];
        
        [s_twitterController dismissModalViewControllerAnimated:YES];
        [s_twitterController release];
        s_twitterController = nil;
    };
    
    [s_twitterController presentViewController:twitter animated:YES completion:nil];
	return YES;
}

@implementation AEStandardCommands

-(id)initWithSystem:(id<SESystem>)system
{
	if ((self = [super init]))
	{
		_system = system; // will exist for the same time as this instance, no need to retain
	}
	return self;
}

-(void)assistantDismissed
{
	if (s_twitterController)
    {
        NSLog(@"AE Standard: Dismissing tweet controller.");
		[s_twitterController dismissModalViewControllerAnimated:NO];
    	[s_twitterController release];
    	s_twitterController = nil;
	}
}

- (BOOL)handleLaunchMatch:(id<AEPatternMatch>)match context:(id<SEContext>)ctx {
    
    // check if this is allowed
    static SBAwayController* awayController = [objc_getClass("SBAwayController") sharedAwayController];
    static id<SBDeviceLockController> lockController = [objc_getClass("SBDeviceLockController") sharedController];
    
    if ([awayController respondsToSelector:@selector(isDeviceLocked)]
        && (bool)[awayController isDeviceLocked] && (bool)[awayController isPasswordProtected])
    {
        [ctx sendAddViewsUtteranceView:[_system localizedString:@"Sorry, I don't know your lockscreen password."]];
        [ctx sendRequestCompleted];
        return YES;
    }
    else if ([lockController respondsToSelector:@selector(isDeviceLocked)]
             && (bool)[lockController isDeviceLocked] && (bool)[lockController isPasswordProtected])
    {
        [ctx sendAddViewsUtteranceView:[_system localizedString:@"Sorry, I don't know your lockscreen password."]];
        [ctx sendRequestCompleted];
        return YES;
    }
    
    // allowed, continue...
    
	NSString *appname = [[[match namedElement:@"app"] mutableCopy] autorelease];

    if ([appname isEqualToString:@"nava gone"] || [appname isEqualToString:@"navvy gone"])
		[appname setString:@"Navigon"];
    
	id app = AEApplicationForDisplayName(appname);
	if (app) {
		[ctx sendAddViewsUtteranceView:[NSString stringWithFormat:[_system localizedString:@"Launching %@"], [appname stringWithFirstUppercase]]];
		//sleep(2);
		[ctx dismissAssistant];
		//[[DSDisplayController sharedInstance] activateApplication:app animated:YES];
		[[LibDisplay sharedInstance] activateApplication:app animated:YES];
	}
	
	else
		[ctx sendAddViewsUtteranceView:[NSString stringWithFormat:[_system localizedString:@"I'm sorry, but I couldn't find any application named %@"], [appname stringWithFirstUppercase]]];
	
	[ctx sendRequestCompleted];
	return YES;
}

- (BOOL)handleKillMatch:(id<AEPatternMatch>)match context:(id<SEContext>)ctx {
    static Class _SBApplicationController = objc_getClass("SBApplicationController");
    id appController = [_SBApplicationController sharedInstance];
    static Class _SBAppSwitcherController = objc_getClass("SBAppSwitcherController");
    id appSwitcher = [_SBAppSwitcherController sharedInstance];
    
	NSMutableString *appname = [[[match namedElement:@"app"] mutableCopy] autorelease];

	if ([appname isEqualToString:@"nava gone"] || [appname isEqualToString:@"navvy gone"])
		[appname setString:@"Navigon"];
	
	if ([appname isEqualToString:@"all"] || [appname isEqualToString:@"every"]) {
		[ctx sendAddViewsUtteranceView:[_system localizedString:@"Killing all applications."]];
		for (id app in [appController allApplications]) {
			if ([[app process] isRunning])
			{
                //[[DSDisplayController sharedInstance] exitApplication:app animated:YES force:NO];
				[[LibDisplay sharedInstance] quitApplication:app removeFromSwitcher:YES];
            }
            //[appSwitcher _removeApplicationFromRecents:app]; // probably make configurable
		}
		
		[ctx sendRequestCompleted];
		return YES;
	}
	
	id app = AEApplicationForDisplayName(appname);
	if (app) {
		[ctx sendAddViewsUtteranceView:[NSString stringWithFormat:@"Killing application %@", [appname stringWithFirstUppercase]]];
		//[[DSDisplayController sharedInstance] exitApplication:app animated:YES force:NO];
        [[LibDisplay sharedInstance] quitApplication:app removeFromSwitcher:YES];
		//[appSwitcher _removeApplicationFromRecents:app]; // probably make configurable
	}
	else {
        [ctx sendAddViewsUtteranceView:[NSString stringWithFormat:[_system localizedString:@"I'm sorry, but I couldn't find any application named %@"], [appname stringWithFirstUppercase]]];
    }
	[ctx sendRequestCompleted];
	return YES;
}

- (BOOL)handleRespringMatch:(id<AEPatternMatch>)match context:(id<SEContext>)ctx {
	[ctx sendAddViewsUtteranceView:[_system localizedString:@"As you wish."]];
	sleep(2);
	
	exit(0);	//system("killall SpringBoard");

	return YES;
}

- (BOOL)handleLockMatch:(id<AEPatternMatch>)match context:(id<SEContext>)ctx {
	[ctx sendAddViewsUtteranceView:[_system localizedString:@"Locking..."]];
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5*NSEC_PER_SEC), dispatch_get_current_queue(), ^{
		[[objc_getClass("SBUIController") sharedInstance] lockFromSource:0];
	});
	
	[ctx sendRequestCompleted];
	return YES;
}

- (BOOL)handleRebootMatch:(id<AEPatternMatch>)match context:(id<SEContext>)ctx {
	[ctx sendAddViewsUtteranceView:[_system localizedString:@"Rebooting at will!"]];
	// TODO: Add a nice 'Are you sure?' snippet
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2*NSEC_PER_SEC), dispatch_get_current_queue(), ^{
		[[UIApplication sharedApplication] reboot];
	});
	
	[ctx sendRequestCompleted];
	return YES;
}

- (BOOL)handleShutdownMatch:(id<AEPatternMatch>)match context:(id<SEContext>)ctx {
	[ctx sendAddViewsUtteranceView:[_system localizedString:@"Powering off right now."]];
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2*NSEC_PER_SEC), dispatch_get_current_queue(), ^{
		[[UIApplication sharedApplication] powerDown];
	});
	
	[ctx sendRequestCompleted];
	return YES;
}

-(BOOL)handleSayMatch:(id<AEPatternMatch>)match context:(id<SEContext>)ctx {
    
    [ctx sendAddViewsUtteranceView:[match namedElement:@"what"]];
    [ctx sendRequestCompleted];
    return YES;
}

- (BOOL)handleBrightnessMatch:(id<AEPatternMatch>)match context:(id<SEContext>)ctx {
	return YES;
}

- (BOOL)handleBrightnessSetterMatch:(id<AEPatternMatch>)match context:(id<SEContext>)ctx {
	NSString* p = [match namedElement:@"p"];
	if (!p) return NO;

	// remove % at the end of the word (just in case)
	char ps[16];
	strncpy(ps, [p UTF8String], 15); ps[15]=0;
	int len = strlen(ps);
	if (len > 0 && ps[len-1] == '%') ps[len-1] = 0;
	
	float val = atof(ps)/100.0f;
	if (val <= 0.0f) val = 0.01f;
	else if (val > 1.0f) val = 1.0f;

    UIApplication* app = [UIApplication sharedApplication];	
	if ([app respondsToSelector:@selector(setBacklightLevel:permanently:)])
		[app setBacklightLevel:val permanently:YES];
	else if ([app respondsToSelector:@selector(setBacklightLevel:)])
		[app setBacklightLevel:val];
	else
	{
		static Class _SBBrightnessController = objc_getClass("SBBrightnessController");
    	[[_SBBrightnessController sharedBrightnessController] setBrightnessLevel:val];
	}


	//GSEventSetBacklightLevel(val);
    //static Class _SBBrightnessController = objc_getClass("SBBrightnessController");
    //[[_SBBrightnessController sharedBrightnessController] setBrightnessLevel:val];   

	[ctx sendAddViewsUtteranceView:[_system localizedString:@"As you wish."]];
	[ctx sendRequestCompleted];
	return YES;
}

- (BOOL)handleBatteryGetterMatch:(id<AEPatternMatch>)match context:(id<SEContext>)ctx {
    
    static Class _SBUIController = objc_getClass("SBUIController");
    if (!_SBUIController) return NO;
    
    int perc = (int)[(SBUIController*)[_SBUIController sharedInstance] curvedBatteryCapacityAsPercentage];
    
    [ctx sendAddViewsUtteranceView:[NSString stringWithFormat:[_system localizedString:@"Battery at %d %%."], perc]];
	[ctx sendRequestCompleted];
    
	return YES;
}

- (BOOL)handleRandomGetterMatch:(id<AEPatternMatch>)match context:(id<SEContext>)ctx {
	[ctx sendAddViewsUtteranceView:[_system localizedString:@"Getting you a random number..."]];
	
	srand(time(NULL));
	int r = rand() % 1001;
	[ctx sendAddViewsSnippet:@"AERandomSnippet" properties:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%i", r] forKey:@"number"]];
	
	[ctx sendRequestCompleted];
	return YES;
}

- (BOOL)handleWouldGetterMatch:(id<AEPatternMatch>)match context:(id<SEContext>)ctx {
	srand(time(NULL));
	int r = rand() % 2;
	NSString *s = r>0 ? [_system localizedString:@"Yes, most certainly."] : [_system localizedString:@"No, that's disturbing."];
	
	[ctx sendAddViewsUtteranceView:s];
	
	[ctx sendRequestCompleted];
	return YES;
}

-(BOOL)handleTweetMatch:(id<AEPatternMatch>)match context:(id<SEContext>)ctx {
	NSString* tweetText = [match namedElement:@"what"];
    if (!tweetText) tweetText = @"";
    
	if ([tweetText length] == 0) // just preview
	{
    	if (AEPreviewTweet(tweetText))
       		[ctx sendAddViewsUtteranceView:[_system localizedString:@"OK, here is your tweet."]];
    	else
        	[ctx sendAddViewsUtteranceView:[_system localizedString:@"Sorry, I was unable to do that."]]; 
	}
	else // send immediately
		AESendTweet(tweetText);    

    [ctx sendRequestCompleted];
    return YES;
}

-(BOOL)handlePreviewTweetMatch:(id<AEPatternMatch>)match context:(id<SEContext>)ctx {
	NSString* tweetText = [match namedElement:@"what"];
	if (!tweetText) tweetText = @"";
	
	if (AEPreviewTweet(tweetText))
		[ctx sendAddViewsUtteranceView:[_system localizedString:@"OK, here is your tweet."]];
	else
		[ctx sendAddViewsUtteranceView:[_system localizedString:@"Sorry, I was unable to do that."]];
 
    [ctx sendRequestCompleted];
    return YES;
}

-(BOOL)handleDismissMatch:(id<AEPatternMatch>)match context:(id<SEContext>)ctx {
	[ctx dismissAssistant];
	[ctx sendRequestCompleted];
	return YES;
}
	

- (void)patternsForLang:(NSString*)lang inSystem:(id<SESystem>)system {
	[system registerNamedPattern:@"LaunchApp" target:self selector:@selector(handleLaunchMatch:context:)];
	[system registerNamedPattern:@"KillApp" target:self selector:@selector(handleKillMatch:context:)];
	
	[system registerNamedPattern:@"PerformRespring" target:self selector:@selector(handleRespringMatch:context:)];
	[system registerNamedPattern:@"PerformLock" target:self selector:@selector(handleLockMatch:context:)];
	[system registerNamedPattern:@"PerformReboot" target:self selector:@selector(handleRebootMatch:context:)];
	[system registerNamedPattern:@"PerformShutdown" target:self selector:@selector(handleShutdownMatch:context:)];
	
	/*[system registerNamedPattern:@"BrightnessController" target:self selector:@selector(handleBrightnessMatch:context:)];
	[system registerNamedPattern:@"BrightnessSetter" target:self selector:@selector(handleBrightnessSetterMatch:context:)];*/
	[system registerNamedPattern:@"BatteryGetter" target:self selector:@selector(handleBatteryGetterMatch:context:)];
	[system registerNamedPattern:@"BrightnessSetter" target:self selector:@selector(handleBrightnessSetterMatch:context:)];
	
	[system registerNamedPattern:@"RandomGetter" target:self selector:@selector(handleRandomGetterMatch:context:)];
	[system registerNamedPattern:@"WouldShouldGetter" target:self selector:@selector(handleWouldGetterMatch:context:)];
    [system registerNamedPattern:@"Say" target:self selector:@selector(handleSayMatch:context:)];
	[system registerNamedPattern:@"Dismiss" target:self selector:@selector(handleDismissMatch:context:)];

	[system registerNamedPattern:@"Tweet" target:self selector:@selector(handleTweetMatch:context:)];
    [system registerNamedPattern:@"PreviewTweet" target:self selector:@selector(handlePreviewTweetMatch:context:)];
}
@end
// vim:ft=objc
