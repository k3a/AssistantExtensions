//
//  YouTubeSnippet.h
//  YouTubeSnippet
//
//  Created by K3A on 12/18/11.
//  Copyright (c) 2011 K3A.me. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SiriObjects.h"

@interface K3AYouTubeSnippet : NSObject<SESnippet,UITableViewDataSource,UITableViewDelegate> {
    UITableView* _view;
    IBOutlet UIView* _helloNib;
    IBOutlet UILabel* _helloLabel;
    
    NSArray* _results;
    NSString* _query;
    NSArray* _thumbs;
}

- (id)initWithProperties:(NSDictionary*)props;
- (id)view;

@end



// principal class
@interface K3AYouTube : NSObject<SEExtension> 

-(id)initWithSystem:(id<SESystem>)system;

-(NSString*)author;
-(NSString*)name;
-(NSString*)description;
-(NSString*)website;

@end


// helpers
inline NSString* urlEncode(NSString* unencodedString)
{
    NSString * encodedString =
    (NSString *)CFURLCreateStringByAddingPercentEscapes( NULL, (CFStringRef)unencodedString, NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8 );
    return [encodedString autorelease];
}