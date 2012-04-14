//
//  YouTubeCommands.mm
//  YouTube
//
//  Created by K3A on 12/29/11.
//  Copyright (c) 2011 K3A.me. All rights reserved.
//

#import "YouTubeCommands.h"
#import "AEYTASIHTTPRequest.h"

@implementation K3AYouTubeCommands

-(id)init 
{
    if ( (self = [super init]) )
    {
        _jsonParser = [[AEYTSBJsonParser alloc] init];
        _queue = [[NSOperationQueue alloc] init];
        [_queue setMaxConcurrentOperationCount:4];
    }
    return self;
}

-(void)dealloc
{
    [_jsonParser release];
    [_queue release];
	[super dealloc];
}

-(void)processRequest:(NSString*)q
{
    // create request url
    NSString* strURL = [NSString stringWithFormat:@"http://gdata.youtube.com/feeds/api/videos?q=%@&orderby=relevance&start-index=1&max-results=7&v=2&format=1&alt=jsonc", urlEncode(q)];
    NSURL *url = [NSURL URLWithString:strURL];
    
    AEYTASIHTTPRequest *request = [AEYTASIHTTPRequest requestWithURL:url];
    [request setFailedBlock:
    ^{
        [_ctx sendAddViewsUtteranceView:@"Sorry, I can't do that right now."];
        [_ctx sendRequestCompleted];
        _ctx = nil;
    }];
    
    // main request
    [request startSynchronous];
    
    if (!_ctx) return; // failed
    
    NSString *responseString = [request responseString];
    NSObject** arrThumbs = NULL;
    
    NSError* err=nil;
    NSDictionary* obj = [_jsonParser objectWithString:responseString error:&err];
    NSArray* arrEntries = [[obj objectForKey:@"data"] objectForKey:@"items"];
    if (err || !obj || !arrEntries)
    {
        [_ctx sendAddViewsUtteranceView:@"Sorry, an unexpected response returned."];
        [_ctx sendRequestCompleted];
        _ctx = nil;
        return;
    }
    
    NSLog(@"Found %u YouTube results...", [arrEntries count]);
    if ([arrEntries count] == 0)
    {
        [_ctx sendAddViewsUtteranceView:@"Nothing has been found."];
        [_ctx sendRequestCompleted];
        _ctx = nil;
        return;
    }
    
    arrThumbs = new NSData*[ [arrEntries count] ];
    
    unsigned idx=0;
    for (NSDictionary* item in arrEntries)
    {
        NSString* thumbUrlStr = [[item objectForKey:@"thumbnail"] objectForKey:@"sqDefault"];
        NSURL* thumbUrl = [NSURL URLWithString:thumbUrlStr];
        AEYTASIHTTPRequest *thumbRequest = [AEYTASIHTTPRequest requestWithURL:thumbUrl];
        [thumbRequest setTag:idx++];
        [thumbRequest setCompletionBlock:
         ^{
             arrThumbs[thumbRequest.tag] = [[thumbRequest responseData] retain];
         }];
        [thumbRequest setFailedBlock:
         ^{
             NSLog(@"Youtube snippet: Thumbnail download failed");
             arrThumbs[thumbRequest.tag] = [[NSNull null] retain];
         }];
        [_queue addOperation:thumbRequest];
    }
    
    // wait for thumbnails to be downloaded
    [_queue waitUntilAllOperationsAreFinished];
    
    NSMutableArray* arrRealThumbs = [NSMutableArray array];
    for (int i=0; i<[arrEntries count]; i++)
	{
		NSData* obj = arrThumbs[i];
		if (!obj) obj = [NSData data];
        [arrRealThumbs addObject:obj];
	}
    
    // create and send snippet 
    NSDictionary* snipProps = [NSDictionary dictionaryWithObjectsAndKeys:arrEntries,@"results",q,@"query",arrRealThumbs,@"thumbs", nil];
    [_ctx sendAddViewsSnippet:@"K3AYouTubeSnippet" properties:snipProps];
    [_ctx sendRequestCompleted];
    
    _ctx = nil;
    
    // clean memory
    for (int i=0; i<[arrEntries count]; i++)
        [arrThumbs[i] release];
    delete[] arrThumbs;
}

-(BOOL)handleSpeech:(NSString*)text tokens:(NSArray*)tokens tokenSet:(NSSet*)tokenset context:(id<SEContext>)ctx
{
    if (_ctx) return NO; // already preocessing
    
    // reacts to only one token - "test" 
	if ([tokenset containsObject:@"youtube"] || ([tokenset containsObject:@"you"] && [tokenset containsObject:@"tube"]))
	{
        _ctx = ctx;
        
        NSMutableString* q = [NSMutableString string];
        for (int num = 0; num < [tokens count]; num++)
        {
            NSString* str = [tokens objectAtIndex:num];
            
            if ([str isEqualToString:@"youtube"]) // skip youtube
                continue;
            else if (num+2 == [tokens count] && [str isEqualToString:@"on"]) // skip on youtube
                continue;
            else if (num == 0 && ([str isEqualToString:@"search"] || [str isEqualToString:@"find"])) // skip search/find
                continue;
            else if (num == 0 && num+1 < [tokens count] && [str isEqualToString:@"look"] && [[tokens objectAtIndex:num+1] isEqualToString:@"up"]) // skip look up
            {
                num++;
                continue;
            }
            else
                [q appendFormat:@"%@ ", str];
        }

        // reflection...
        NSString* str = @"Searching YouTube for you...";
        [ctx sendAddViewsUtteranceView:str speakableText:str dialogPhase:@"Reflection" scrollToTop:NO temporary:NO];
		
        NSLog(@"Youtube query: '%@'", q);
        
        // start async req
        [self performSelectorInBackground:@selector(processRequest:) withObject:q];

		return YES; // inform the system that the command has been handled (ignore the original one from the server)
	}

	return NO;	
}

@end
