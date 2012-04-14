//
//  AEStringAdditions.h
//  AssistantExtensions
//
//  Created by Kexik on 11/30/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (AEAdditions)

/// returns a float between 0 and 1.0 with better matches being nearer 1.0
-(float) similarityWithString:(NSString*) otherString;
-(NSString*)stringWithFirstUppercase;
-(NSString*)urlEncodedString;

// Created by http://www.cocoadev.com/index.pl?NSStringSoundex
- (NSString*) soundexString;
- (BOOL) soundsLikeString:(NSString*) aString;

// Created by http://files.codeandstuff.com/metaphone/
- (NSString*)metaphone;

-(BOOL)isFuzzyEqualTo:(NSString*)aStr;

@end
