//
//  YouTubeSnippet.m
//  YouTubeSnippet
//
//  Created by K3A on 12/18/11.
//  Copyright (c) 2011 K3A.me. All rights reserved.
//

#import "YouTubeSnippet.h"
#import "YouTubeCommands.h"
#import <Foundation/Foundation.h>

@implementation K3AYouTubeSnippet

- (id)view
{
    return _view;
}

- (void)dealloc
{
    [_view release];
    [_results release];
    [_query release];
    [_thumbs release];
	[super dealloc];
}

- (id)initWithProperties:(NSDictionary*)props;
{
    if ( (self = [super init]) )
    {
        // here we load a view from a nib file
        /*if (![[NSBundle bundleForClass:[self class]] loadNibNamed:@"HelloNib" owner:self options:nil])
        {
            NSLog(@"Warning! Could not load nib file.\n");
            return NO;
        }
        _view = [_helloNib retain]; 
        [_helloLabel setText:[props objectForKey:@"text"]]; // text from HelloCommands*/
        
        //NSLog(@"YouTube Snippet: %@", props);
        
        _results = [[props objectForKey:@"results"] retain];
        _thumbs = [[props objectForKey:@"thumbs"] retain];
        _query = [[props objectForKey:@"query"] retain];
        
        /*if ([_thumbs count] != [_results count])
        {
            [self release];
            return nil;
        }*/
        
        // ...but you are free to do GUI programatically
        _view = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        [_view setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        [_view setBackgroundColor:[UIColor clearColor]];
        [_view setDelegate:self];
        [_view setDataSource:self];
    }
    return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_results count]+1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"YoutubeResult";
    
    if (indexPath.row < [_results count])
    {
        NSString* thumbUrl = [[[_results objectAtIndex:indexPath.row] objectForKey:@"thumbnail"] objectForKey:@"sqDefault"];
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        }
        
        cell.textLabel.text = [[_results objectAtIndex:indexPath.row] objectForKey:@"title"];
        cell.imageView.image = [UIImage imageWithData:[_thumbs objectAtIndex:indexPath.row]];
    }
    else
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        }
        cell.textLabel.text = @"More...";
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.textLabel.textColor = [UIColor whiteColor];
        //cell.contentView.backgroundColor = [UIColor clearColor];
    }
    
    // Configure the cell...
    if (indexPath.row < [_results count])
    {
        NSData* thumbData = [_thumbs objectAtIndex:indexPath.row];
        if ([thumbData isKindOfClass:[NSNull class]]) thumbData = nil;
        
        cell.textLabel.text = [[_results objectAtIndex:indexPath.row] objectForKey:@"title"];
        cell.imageView.image = [UIImage imageWithData:thumbData];
    }
    else
        cell.textLabel.text = @"More...";
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    /*UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Title" message:@"Selected!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    
    [alert show];
    [alert release];*/
    
    NSString* url;
    if (indexPath.row < [_results count])
        url = [NSString stringWithFormat:@"http://www.youtube.com/watch?v=%@",
                     [[_results objectAtIndex:indexPath.row] objectForKey:@"id"]];
    else
        url = [NSString stringWithFormat:@"http://m.youtube.com/results?q=%@", urlEncode(_query)];
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}

@end

// -------------------

@implementation K3AYouTube

// required initialization
-(id)initWithSystem:(id<SESystem>)system
{
    if ( (self = [super init]) )
    {
        [system registerCommand:[K3AYouTubeCommands class]];
        [system registerSnippet:[K3AYouTubeSnippet class]];
    }
    return self;
}

// optional info about extension
-(NSString*)author
{
    return @"K3A";
}
-(NSString*)name
{
    return @"YouTube";
}
-(NSString*)description
{
    return @"YouTube search";
}
-(NSString*)website
{
    return @"www.k3a.me";
}

@end
