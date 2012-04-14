#import "AESBSTogglesCommands.h"

@implementation AESBSTogglesCommands

-(id)init
{
	if ( (self = [super init]) )
	{
		// additional initialization
	}
	return self;
}

-(void)dealloc
{
	// additional cleaning
	[super dealloc];
}

-(BOOL)handleSpeech:(NSString*)text tokens:(NSArray*)tokens tokenSet:(NSSet*)tokenset context:(id<SEContext>)ctx
{
	// logging useful during development
	// NSLog(@">> AESBSTogglesCommands handleSpeech: %@", text);

	// react to recognized tokens (what happen or what happened)
	if ([tokens count] >= 2 && 
		[[tokens objectAtIndex:0] isEqualToString:@"what"] && 
		( [tokenset containsObject:@"happen"] || [tokenset containsObject:@"happened"] )
	)
	{
		// send a simple utterance response:
		[ctx sendAddViewsUtteranceView:@"Somebody set up us the bomb!"];
		
		// Inform the assistant that this is end of the request
		// For more complex extensions, you can spawn an additional thread and process request asynchronly, 
		// ending with sending "request completed"
		[ctx sendRequestCompleted];

		return YES; // the command has been handled by our extension (ignore the original one from the server)
	}

	return NO;
}

@end
// vim:ft=objc
