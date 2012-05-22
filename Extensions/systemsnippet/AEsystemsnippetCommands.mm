#import "AEsystemsnippetCommands.h"

@implementation AEsystemsnippetCommands

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
	// NSLog(@">> AEsystemsnippetCommands handleSpeech: %@", text);

	// react to recognized tokens
	if ([tokens count] == 1 && 
		[[tokens objectAtIndex:0] isEqualToString:@"object"]
	)
	{
		NSMutableArray* views = [NSMutableArray array];
	
		NSMutableDictionary* clock = [NSMutableDictionary dictionary];
		[clock setObject:@"Object" forKey:@"class"];
		[clock setObject:@"com.apple.ace.clock" forKey:@"group"];
	
		NSMutableDictionary* props = [NSMutableDictionary dictionary];
		[props setObject:@"United States" forKey:@"countryName"];
		[props setObject:@"US" forKey:@"countryCode"];
		[props setObject:@"America/New_York" forKey:@"timezoneId"];
		[props setObject:@"North Smithfield" forKey:@"cityName"];
		[props setObject:@"North Smithfield" forKey:@"unlocalizedCityName"];
		[props setObject:@"United States" forKey:@"unlocalizedCountryName"];

		[clock setObject:props forKey:@"properties"];

		NSMutableDictionary* snipProps = [NSMutableDictionary dictionary];
		[snipProps setObject:[NSArray arrayWithObject:clock] forKey:@"clocks"];

		NSMutableDictionary* v = [NSMutableDictionary dictionary];
		[v setObject:@"Snippet" forKey:@"class"];
		[v setObject:@"com.apple.ace.clock" forKey:@"group"];
		[v setObject:snipProps forKey:@"properties"];

		[views addObject:v];

		// send a simple utterance response:
		[ctx sendAddViews:views];
		
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
