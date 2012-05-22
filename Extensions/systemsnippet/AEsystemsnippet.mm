#import "AEsystemsnippet.h"
#import "AEsystemsnippetCommands.h"

@implementation AEsystemsnippet

// required initialization
-(id)initWithSystem:(id<SESystem>)system
{
	if ( (self = [super init]) )
	{
		// register all extension classes provided
		[system registerCommand:[AEsystemsnippetCommands class]];
	}
	return self;
}

// optional info about extension
-(NSString*)author
{
	return @"K3A";
}
-(NSString*)name
{
	return @"systemsnippet";
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
