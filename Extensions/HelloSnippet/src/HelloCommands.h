//
//  HelloCommands.h
//  HelloSnippet
//
//  Created by K3A on 12/29/11.
//  Copyright (c) 2011 K3A.me. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SiriObjects.h"


@interface K3AHelloCommands : NSObject<SECommand> {
    id<SESystem> _system;
}

-(BOOL)handleSpeech:(NSString*)text tokens:(NSArray*)tokens tokenSet:(NSSet*)tokenset context:(id<SEContext>)ctx;

@end
