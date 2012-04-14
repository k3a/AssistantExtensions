//
//  AEChatBot.mm
//  SiriCommands
//
//  Created by K3A on 2/1/12.
//  Copyright (c) 2012 K3A. All rights reserved.
//

#import "AEChatBot.h"
#import "AEChatBotCommands.h"

@implementation AEChatBot

// required initialization
-(id)initWithSystem:(id<SESystem>)system
{
	if ( (self = [super init]) )
	{
		// register all extension classes provided
		[system registerCommand:[AEChatBotCommands class]];
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
	return @"ChatBot";
}
-(NSString*)description
{
	return @"AIML ChatBot";
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






