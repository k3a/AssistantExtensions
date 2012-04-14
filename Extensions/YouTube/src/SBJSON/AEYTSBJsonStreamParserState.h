/*
 Copyright (c) 2010, Stig Brautaset.
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are
 met:
 
   Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
  
   Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.
 
   Neither the name of the the author nor the names of its contributors
   may be used to endorse or promote products derived from this software
   without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
 IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>

#import "AEYTSBJsonTokeniser.h"
#import "AEYTSBJsonStreamParser.h"

@interface AEYTSBJsonStreamParserState : NSObject
+ (id)sharedInstance;
- (BOOL)parser:(AEYTSBJsonStreamParser*)parser shouldAcceptToken:(sbjson_token_t)token;
- (AEYTSBJsonStreamParserStatus)parserShouldReturn:(AEYTSBJsonStreamParser*)parser;
- (void)parser:(AEYTSBJsonStreamParser*)parser shouldTransitionTo:(sbjson_token_t)tok;
- (BOOL)needKey;

- (NSString*)name;

@end

@interface AEYTSBJsonStreamParserStateStart : AEYTSBJsonStreamParserState
@end

@interface AEYTSBJsonStreamParserStateComplete : AEYTSBJsonStreamParserState
@end

@interface AEYTSBJsonStreamParserStateError : AEYTSBJsonStreamParserState
@end


@interface AEYTSBJsonStreamParserStateObjectStart : AEYTSBJsonStreamParserState
@end

@interface AEYTSBJsonStreamParserStateObjectGotKey : AEYTSBJsonStreamParserState
@end

@interface AEYTSBJsonStreamParserStateObjectSeparator : AEYTSBJsonStreamParserState
@end

@interface AEYTSBJsonStreamParserStateObjectGotValue : AEYTSBJsonStreamParserState
@end

@interface AEYTSBJsonStreamParserStateObjectNeedKey : AEYTSBJsonStreamParserState
@end

@interface AEYTSBJsonStreamParserStateArrayStart : AEYTSBJsonStreamParserState
@end

@interface AEYTSBJsonStreamParserStateArrayGotValue : AEYTSBJsonStreamParserState
@end

@interface AEYTSBJsonStreamParserStateArrayNeedValue : AEYTSBJsonStreamParserState
@end
