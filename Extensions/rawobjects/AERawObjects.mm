#import "AERawObjects.h"

@implementation AERawObjects

// required initialization
-(id)initWithSystem:(id<SESystem>)system
{
	if ( (self = [super init]) )
	{
		// register commands, snippets, add filters, etc
		[system setServerToClientFilter: [NSArray arrayWithObject:@"AddViews"]];
	}
	return self;
}

// two methods for intercepting/modifying communication
/*-(SOObject*)clientToServerObject:(SOObject*)dict context:(id<SEContext>)ctx
{
	NSLog(@"CLIENT->SERVER: %@", dict);
	return dict;
}*/
-(SOObject*)serverToClientObject:(SOObject*)dict context:(id<SEContext>)ctx
{
	NSLog(@"SERVER->CLIENT: %@", dict);

	NSMutableArray* views = [[dict objectForKey:@"properties"] objectForKey:@"views"];
	if ([views count] != 2) return dict; // we are looking for two views

	NSMutableDictionary* snippetView = [views objectAtIndex:1];

	if (![[snippetView objectForKey:@"class"] isEqualToString:@"ForecastSnippet"])
		return dict; // object at index 1 is not forecast snippet - for us not interesting

	// now we know we have a weather response, get the place for which it has been issued
	NSMutableDictionary* originalWeather = [[[[views objectAtIndex:1] objectForKey:@"properties"] objectForKey:@"aceWeathers"] objectAtIndex:0];
	if (!originalWeather) return dict; // umm, there is something missing

	// ... get properties
	originalWeather = [originalWeather objectForKey:@"properties"];

	// get location
	NSMutableDictionary* weatherLocation = [[originalWeather objectForKey:@"weatherLocation"] objectForKey:@"properties"];
	NSLog(@"Original weather issued for: %@, %@, %@", [weatherLocation objectForKey:@"city"], [weatherLocation objectForKey:@"countryCode"], [weatherLocation objectForKey:@"locationId"]);
	
	//if ([[weatherLocation objectForKey:@"countryCode"] isEqualToString:@"Czech Republic"])
	//{
		NSLog(@"Getting more exact weather...");
		
		// modify utterance
		[views replaceObjectAtIndex:0 withObject:[ctx createAssistantUtteranceView:@"Here are more exact weather data for you."]];

		// modify snippet
		NSMutableDictionary* currentConditions = [originalWeather objectForKey:@"currentConditions"];
		[[currentConditions objectForKey:@"properties"] setObject:@"-100" forKey:@"temperature"];

	//}

	return dict;
}

// optional info about extension
-(NSString*)author
{
	return @"K3A";
}
-(NSString*)name
{
	return @"RawObjects";
}
-(NSString*)description
{
	return @"An example of how to intercept, modify and serve requests using raw ace objects";
}
-(NSString*)website
{
	return @"ae.k3a.me";
}
-(NSString*)versionRequirement
{
	return @"1.0.2";
}

@end
// vim:ft=objc
