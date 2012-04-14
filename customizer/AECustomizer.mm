#import "AECustomizer.h"
#import "AECustomizerCommands.h"

@implementation AECustomizer

// required initialization
-(id)initWithSystem:(id<SESystem>)system
{
	if ( (self = [super init]) )
	{
		// register all extension classes provided
		[system registerCommand:[AECustomizerCommands class]];
	}
	return self;
}

// optional info about extension
-(NSString*)author
{
	return @"theiostream";
}
-(NSString*)name
{
	return @"Customizer";
}
-(NSString*)description
{
	return @"An awesome extension for Siri!";
}
-(NSString*)website
{
	return @"ae.k3a.me";
}
-(NSString*)versionRequirement
{
	return @"1.0.1";
}

@end
// vim:ft=objc
