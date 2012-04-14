#import "AELocationTest.h"
#import "AELocationTestCommands.h"

@implementation AELocationTest

// required initialization
-(id)initWithSystem:(id<SESystem>)system
{
	if ( (self = [super init]) )
	{
		// register all extension classes provided
		[system registerCommand:[AELocationTestCommands class]];
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
	return @"LocationTest";
}
-(NSString*)description
{
	return @"Location services test";
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
