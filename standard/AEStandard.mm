#import "AEStandard.h"
#import "AEStandardCommands.h"
#import "AERandomSnippet.h"

@implementation AEStandard

// required initialization
-(id)initWithSystem:(id<SESystem>)system {
	if ((self = [super init])) {
		[system registerCommand:[AEStandardCommands class]];
		[system registerSnippet:[AERandomSnippet class]];
	}
	
	return self;
}

// optional info about extension
-(NSString*)author
{
	return @"theiostream & k3a";
}
-(NSString*)name
{
	return @"Standard";
}
-(NSString*)description
{
	return @"Standard AE commands";
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
