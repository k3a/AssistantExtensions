//
//  AEYTASIInputStream.h
//  Part of AEYTASIHTTPRequest -> http://allseeing-i.com/AEYTASIHTTPRequest
//
//  Created by Ben Copsey on 10/08/2009.
//  Copyright 2009 All-Seeing Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AEYTASIHTTPRequest;

// This is a wrapper for NSInputStream that pretends to be an NSInputStream itself
// Subclassing NSInputStream seems to be tricky, and may involve overriding undocumented methods, so we'll cheat instead.
// It is used by AEYTASIHTTPRequest whenever we have a request body, and handles measuring and throttling the bandwidth used for uploading

@interface AEYTASIInputStream : NSObject {
	NSInputStream *stream;
	AEYTASIHTTPRequest *request;
}
+ (id)inputStreamWithFileAtPath:(NSString *)path request:(AEYTASIHTTPRequest *)request;
+ (id)inputStreamWithData:(NSData *)data request:(AEYTASIHTTPRequest *)request;

@property (retain, nonatomic) NSInputStream *stream;
@property (assign, nonatomic) AEYTASIHTTPRequest *request;
@end
