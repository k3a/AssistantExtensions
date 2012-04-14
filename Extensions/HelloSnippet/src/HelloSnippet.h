//
//  HelloSnippet.h
//  HelloSnippet
//
//  Created by K3A on 12/18/11.
//  Copyright (c) 2011 K3A.me. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SiriObjects.h"

@interface K3AHelloSnippet : NSObject<SESnippet> {
    UIView* _view;
    IBOutlet UIView* _helloNib;
    IBOutlet UILabel* _helloFirstLabel;
    IBOutlet UILabel* _helloSecondLabel;
}

- (id)initWithProperties:(NSDictionary*)props;
- (id)view;

@end



// principal class
@interface K3AHelloSnippetExtension : NSObject<SEExtension> 

-(id)initWithSystem:(id<SESystem>)system;

@end