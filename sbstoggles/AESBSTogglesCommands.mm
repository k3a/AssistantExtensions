#import "AESBSTogglesCommands.h"

#import "AEToggle.h"
#import "../AEStringAdditions.h"

@implementation AESBSTogglesCommands

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


-(BOOL)handleTurnOnMatch:(id<AEPatternMatch>)match context:(id<SEContext>)ctx 
{
    NSString* tog = [match namedElement:@"t"];
    
    // do not break turn on/off alarms
    if ([tog isEqualToString:@"alarm"] || [tog isEqualToString:@"alarms"] || 
        [tog isEqualToString:[_system localizedString:@"alarm"]] ) return NO;
    
    // mywi fix
    if ([tog isEqualToString:@"my wife"]) tog = [NSMutableString stringWithString:@"mywi"];
    // '3 g' fix
    else if ([tog isEqualToString:@"3 g"]) tog = [NSMutableString stringWithString:@"3g"];
    
    NSLog(@"===> ACTION: Turn on toggle %@", tog);
    
    NSString* text = nil;
    AEToggle* togObj = [AEToggle findToggleNamed:tog];
    if (togObj == nil)
    {
        //text = [NSString stringWithFormat:@"Sorry, toggle %@ is not installed.", [tog stringWithFirstUppercase]];
        return NO; // do not handle, allow to handle that by some other extension
    }
    else
    {
        [togObj setState:YES];
        text = [NSString stringWithFormat:[_system localizedString:@"%@ has been turned on."], [tog stringWithFirstUppercase]];
    }
    
    [ctx sendAddViewsUtteranceView:text];
    [ctx sendRequestCompleted];
    
    return YES;
}

-(BOOL)handleTurnOffMatch:(id<AEPatternMatch>)match context:(id<SEContext>)ctx 
{
    NSString* tog = [match namedElement:@"t"];
    
    // do not break turn on/off alarms
    if ([tog isEqualToString:@"alarm"] || [tog isEqualToString:@"alarms"] || 
        [tog isEqualToString:[_system localizedString:@"alarm"]] ) return NO;
    
    // mywi fix
    if ([tog isEqualToString:@"my wife"]) tog = [NSMutableString stringWithString:@"mywi"];
    // '3 g' fix
    else if ([tog isEqualToString:@"3 g"]) tog = [NSMutableString stringWithString:@"3g"];
    
    NSLog(@"===> ACTION: Turn off toggle %@", tog);
    
    NSString* text = nil;
    AEToggle* togObj = [AEToggle findToggleNamed:tog];
    if (togObj == nil)
    {
        //text = [NSString stringWithFormat:@"Sorry, toggle %@ is not installed.", [tog stringWithFirstUppercase]];
        return NO; // do not handle, allow to handle that by some other extension
    }
    else
    {
        [togObj setState:NO];
        text = [NSString stringWithFormat:[_system localizedString:@"%@ has been turned off."], [tog stringWithFirstUppercase]];
    }
    
    [ctx sendAddViewsUtteranceView:text];
    [ctx sendRequestCompleted];
    
    return YES;
}

-(BOOL)handleListMatch:(id<AEPatternMatch>)match context:(id<SEContext>)ctx 
{
    NSLog(@"===> ACTION: List of switches.");
    
    NSMutableString* strSpeak = [NSMutableString stringWithString:[_system localizedString:@"Toggles available:\n"]];
    NSMutableString* str = [NSMutableString stringWithString:[_system localizedString:@"Toggles available:\n"]];
    
    for (NSString* tname in [AEToggle allToggleNames])
    {
        AEToggle* togObj = [AEToggle findToggleNamed:tname];
        if (togObj)
        {
            NSString* tnameUpper = [tname stringWithFirstUppercase];
            
            [str appendFormat:@"%@: %@\n", tnameUpper, [_system localizedString: [togObj state]?@"Enabled":@"Disabled"] ];
            
            [strSpeak appendFormat:@"%@: %@ @{tts#\e\\pause=100\\}\n", 
             tnameUpper, [_system localizedString: [togObj state]?@"Enabled":@"Disabled"] ];
        }
    }
    
    [ctx sendAddViewsUtteranceView:str speakableText:strSpeak];
    [ctx sendRequestCompleted];
    
    return YES;
}

- (void)patternsForLang:(NSString*)lang inSystem:(id<SESystem>)system 
{
    [system registerNamedPattern:@"TurnOn" target:self selector:@selector(handleTurnOnMatch:context:)];
    [system registerNamedPattern:@"TurnOff" target:self selector:@selector(handleTurnOffMatch:context:)];
    [system registerNamedPattern:@"List" target:self selector:@selector(handleListMatch:context:)];
}


@end
// vim:ft=objc































