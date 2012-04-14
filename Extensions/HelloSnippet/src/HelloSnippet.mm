//
//  HelloSnippet.m
//  HelloSnippet
//
//  Created by K3A on 12/18/11.
//  Copyright (c) 2011 K3A.me. All rights reserved.
//

#import "HelloSnippet.h"
#import "HelloCommands.h"
#import <Foundation/Foundation.h>

@implementation K3AHelloSnippet

- (id)view
{
    //NSLog(@">> HelloSnippetController view");
    return _view;
}

- (void)dealloc
{
    NSLog(@">> K3AHelloSnippet dealloc");
    [_view release];
	[super dealloc];
}

- (id)initWithProperties:(NSDictionary*)props system:(id<SESystem>)system
{
	NSLog(@">> K3AHelloSnippet initWithProperties: Properties: %@", props);

    if ( (self = [super init]) )
    {
        // here we load a view from a nib file
        if (![[NSBundle bundleForClass:[self class]] loadNibNamed:@"HelloNib" owner:self options:nil])
        {
            NSLog(@"Warning! Could not load nib file.\n");
            return NO;
        }
        _view = [_helloNib retain];
        [_helloFirstLabel setText:[system localizedString:@"This snippet has been loaded from a nib file."]];
        [_helloSecondLabel setText:[props objectForKey:@"text"]]; // text from HelloCommands
        
        // ...but you are free to do GUI programatically
        //UILabel* lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        //[lbl setText:@"Hello Snippet!"];
        //_view = lbl;
    }
    return self;
}

@end

// -------------------

@implementation K3AHelloSnippetExtension

// required initialization
-(id)initWithSystem:(id<SESystem>)system
{
    if ( (self = [super init]) )
    {
        [system registerCommand:[K3AHelloCommands class]];
        [system registerSnippet:[K3AHelloSnippet class]];
    }
    return self;
}

/*-(void)assistantActivatedWithContext:(id<SEContext>)ctx
{
    // since 1.0.2 developers can use this method for issuing snippets 
    // and utterance view right after the user activates assistant and gives the first request.
    NSLog(@">> K3AHelloSnippet : Assistant activated");
    
    // send views to the assistant
    [ctx sendAddViewsUtteranceView:@"Hello!"];
    
    // completed..
    [ctx sendRequestCompleted];
}*/

@end
