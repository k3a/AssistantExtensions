//
//  SnippetExtensionController.m
//  SnippetExtension
//
//  Created by K3A on 12/18/11.
//  Copyright (c) 2011 K3A.me. All rights reserved.
//

#import "SnippetExtensionController.h"
#import <Foundation/Foundation.h>
#include <objc/runtime.h>

@implementation HelloSnippetController

- (id)view
{
    return _view;
} 

- (void)dealloc
{
    NSLog(@">> SASnippetExtension dealloc");
    [super dealloc];
    [_view release];
}
- (id)initWithAceObject:(id)ace delegate:(id)dlg
{
    NSLog(@">> SASnippetExtension init");
    if ( (self = [super initWithAceObject:ace delegate:dlg]) )
    {
		if (![ace isKindOfClass:objc_getClass("SASnippetExtension")])
        {
            NSLog(@"Received AceObject which is not a SASnippetExtension!");
            [self release];
            return nil;
        }
        
        // create a view
        NSLog(@"SASnippetExtension Props: %@", [ace properties]);
        
        _view = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 310, 100)];
        [(UILabel*)_view setText:@"SASnippetExtension"];
    }
    return self;
}

@end
