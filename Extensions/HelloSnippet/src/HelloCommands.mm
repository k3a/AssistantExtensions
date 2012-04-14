//
//  HelloCommands.mm
//  HelloSnippet
//
//  Created by K3A on 12/29/11.
//  Copyright (c) 2011 K3A.me. All rights reserved.
//

#import "HelloCommands.h"


@implementation K3AHelloCommands

-(id)initWithSystem:(id<SESystem>)system
{
    if ( ([super init]) )
    {
        _system = system; // no need to retain, system remains in memory until the extension is there
    }
    return self;
}

-(void)dealloc
{
	NSLog(@"K3AHelloCommands dealloc");
	[super dealloc];
}

-(BOOL)handleSpeech:(NSString*)text tokens:(NSArray*)tokens tokenSet:(NSSet*)tokenset context:(id<SEContext>)ctx
{
	NSLog(@">> K3AHelloCommands handleSpeech %@", text);
    
    	// reacts to only one token - "test" 
	if ([tokenset count] == 1 && [tokenset containsObject:@"test"])
	{
        // properties for the snippet
        NSDictionary* snipProps = [NSDictionary dictionaryWithObject:[_system localizedString:@"Text passed as a snippet property."] 
                                                              forKey:@"text"];

        // create an array of views
        NSMutableArray* views = [NSMutableArray arrayWithCapacity:1];
        [views addObject:[ctx createAssistantUtteranceView:[_system localizedString:@"Hello Snippet!!"]]];
        [views addObject:[ctx createSnippet:@"K3AHelloSnippet" properties:snipProps]];

        // send views to the assistant
        [ctx sendAddViews:views];

        // alternatively, for utterance response, you can use this call only:
        //[ctx sendAddViewsAssistantUtteranceView:@"Hello Snippet!!"];
        // alternatively, for snippet response you can use this call only:
        //[ctx sendAddViewsSnippet:@"K3AHelloSnippet" properties:snipProps];

        // inform the assistant that this is end of the request
        // you can spawn an additional thread and process request asynchronly, ending with sending "request completed"
        [ctx sendRequestCompleted];

        return YES; // inform the system that the command has been handled (ignore the original one from the server)
	}

	return NO;	
}

-(BOOL)test:(id<AEPatternMatch>)match context:(id<SEContext>)ctx
{
    [ctx sendAddViewsUtteranceView:[NSString stringWithFormat:@"It's working! Matched %@.", [match namedElement:@"what"]]];
    [ctx sendRequestCompleted];
    
    return YES;
}

-(BOOL)age:(id<AEPatternMatch>)match context:(id<SEContext>)ctx
{
    [ctx sendAddViewsUtteranceView:[NSString stringWithFormat:@"Ah yes, you're %@!", [match namedElement:@"age"]]];
    [ctx sendRequestCompleted];
    
    return YES;
}

-(void)patternsForLang:(NSString*)lang inSystem:(id<SESystem>)system
{
    NSLog(@">> K3AHelloCommands patternsForLang - registering patterns for lang %@", lang);
    [system registerPattern:@"test (what:snippet|hello)" selector:@selector(test:context:)];
    [system registerNamedPattern:@"AGE" selector:@selector(age:context:)];
}

@end
