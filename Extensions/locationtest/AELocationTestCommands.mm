#import "AELocationTestCommands.h"

@implementation AELocationTestCommands

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

-(void)process:(id<SEContext>)ctx
{
    SOLocationData loc = [ctx getLocationDataShowReflection:YES];
    if (!loc.valid)
    {
        [ctx sendAddViewsUtteranceView:@"Sorry, I was unable to get your current location."];
        [ctx sendRequestCompleted];
        NSLog(@"Location data not valid.");
        return;
    }
    
    int degrees = loc.latitude;
    double decimal = fabs(loc.latitude - degrees);
    int minutes = decimal * 60;
    double seconds = decimal * 3600 - minutes * 60;
    NSString *lat = [NSString stringWithFormat:@"%d° %d' %1.4f\"",
                     degrees, minutes, seconds];
    degrees = loc.longitude;
    decimal = fabs(loc.longitude - degrees);
    minutes = decimal * 60;
    seconds = decimal * 3600 - minutes * 60;
    NSString *longt = [NSString stringWithFormat:@"%d° %d' %1.4f\"",
                       degrees, minutes, seconds];
    
    
    // send a simple utterance response:
    NSLog(@"Your location: %@, %@", lat, longt);
    [ctx sendAddViewsUtteranceView:[NSString stringWithFormat:@"Your location: %@, %@ - location %d seconds old", lat, longt, loc.age]];
    
    // request completed
    [ctx sendRequestCompleted];
}

-(BOOL)handleSpeech:(NSString*)text tokens:(NSArray*)tokens tokenSet:(NSSet*)tokenset context:(id<SEContext>)ctx
{
	// logging useful during development
	 NSLog(@">> AELocationTestCommands handleSpeech: %@", text);

	// react to recognized tokens (what happen or what happened)
	if ([tokens count] >= 2 && 
		[[tokens objectAtIndex:0] isEqualToString:@"test"] && 
		[tokenset containsObject:@"location"]
	)
	{
        [self performSelectorInBackground:@selector(process:) withObject:ctx];

		return YES; // the command has been handled by our extension (ignore the original one from the server)
	}

	return NO;
}

@end
// vim:ft=objc
