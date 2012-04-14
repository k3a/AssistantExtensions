//
//  YouTubeCommands.h
//  YouTube
//
//  Created by K3A on 12/29/11.
//  Copyright (c) 2011 K3A.me. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SiriObjects.h"
#import "AEYTSBJson.h"
#import "YouTubeSnippet.h"

@interface K3AYouTubeCommands : NSObject<SECommand> {
    id<SEContext> _ctx;
    AEYTSBJsonParser* _jsonParser;
    NSOperationQueue* _queue;
}

-(BOOL)handleSpeech:(NSString*)text tokens:(NSArray*)tokens tokenSet:(NSSet*)tokenset context:(id<SEContext>)ctx;

@end
