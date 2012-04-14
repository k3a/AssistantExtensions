//
//  AEDonate.m
//  AEPrefs
//
//  Created by K3A on 3/20/12.
//  Copyright (c) 2012 K3A. All rights reserved.
//

#import "AEDonate.h"
#import "AEPrefs.h"
#import <Preferences/Preferences.h>

@implementation AEDonate

- (void) dealloc {
    [_tableView release];
    [super dealloc];
}

-(id)initWithParent:(CustomAEController*)parent settings:(NSMutableDictionary*)settings
{
    if ( (self = [super init]) )
    {
        self.parentController = parent; 
        self.rootController = parent.rootController;
        _parent = parent;
        _settings = settings;
        
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, 480-64) style:UITableViewStyleGrouped];
        [_tableView setDelegate:self];
        [_tableView setDataSource:self];
        
        [[self navigationItem] setTitle:@"Donation"];
    }
    return self;
}


- (id) view {
	return _tableView;
}

static BOOL s_doneShown = NO;
-(void)hideDone
{
    [[self navigationItem] setRightBarButtonItem:nil animated:NO];
    s_doneShown = NO;
}
- (void)onDone:(id)sender
{
    [self.view endEditing:TRUE];
    
    // save preferences
    [_parent saveSettings];
    
    /*UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Title" message:@"DONE!"  delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
     [alert show];
     [alert release];*/
    
    [_tableView beginUpdates];
    [_tableView endUpdates];
    
    [self hideDone];
}
-(void)showDone
{
    if (s_doneShown) return;
    
    UIBarButtonItem *anotherButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(onDone:)];
    [[self navigationItem] setRightBarButtonItem:anotherButton animated:YES];
    [anotherButton release];
    
    s_doneShown = YES;
}

// text views
- (void) textFieldDidEndEditing:(UITextField *)textField {
    switch (textField.tag) {
        case 1:
            //NSLog(@"E-Mail: %@", textField.text);
            [_settings setObject:textField.text forKey:@"donation"];
            break;
        default:
            NSLog(@"Unknown textfield %u: %@", textField.tag, textField.text);
            break;
    }
}
- (void) textFieldDidBeginEditing:(UITextField *)textField {
    [self showDone];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
        return 3;
    
	return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    if (indexPath.section == 0)
    {
        if (indexPath.row == 0 || indexPath.row == 2)
            return 80;
    }
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    CGSize sz = tableView.frame.size;
    
    if (indexPath.section == 0)
    {
        if (indexPath.row == 0)
        {
            static NSString *CellIdentifier = @"EADonation";
            
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) 
            {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
                
                UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(8,0,sz.width-35, 80)];
                label.font = [UIFont systemFontOfSize:15];
                label.numberOfLines = 0;
                label.backgroundColor = [UIColor clearColor];
                label.textAlignment = UITextAlignmentCenter;
                label.text = @"AssistantExtensions is free software.\nDevelopment of it was not easy.\nSupport it by donating!";
                
                [cell.contentView addSubview:label];
                [label release];
            }
        }
        if (indexPath.row == 1)
        {
            static NSString *CellIdentifier = @"EAEmail";
            
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) 
            {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
                
                UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(20,9,sz.width/2, 30)];
                label.font = [UIFont boldSystemFontOfSize:18];
                label.backgroundColor = [UIColor clearColor];
                label.text = @"Your price $";
                
                UITextField* text = [[UITextField alloc] initWithFrame:CGRectMake(sz.width/2.3f,12,sz.width/2-20, 30)];
                text.font = [UIFont systemFontOfSize:18];
                text.borderStyle = UITextBorderStyleNone;
                text.autocapitalizationType = UITextAutocapitalizationTypeNone;
                text.placeholder = @"amount";
                text.tag = 1;
                text.text = [_settings objectForKey:@"donation"];
                text.delegate = self;
                
                [cell.contentView addSubview:label];
                [cell.contentView addSubview:text];
                
                [label release];
                [text release];
            }
        }
        else if (indexPath.row == 2)
        {
            static NSString *CellIdentifier = @"AECell";
            
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) 
            {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
                
                UIImageView* iv = [[UIImageView alloc] initWithFrame:CGRectMake(40,10,sz.width-100, 60)];
                [iv setImage:[UIImage imageWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"donate" ofType:@"png"]] ];
                
                [cell.contentView addSubview:iv];
                [iv release];
            }
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if (indexPath.section == 0)
    {
        if (indexPath.row == 2)
        {
            NSString* followUrl = [NSString stringWithFormat:@"http://ae.k3a.me/donate.php?amount=%@", [_settings objectForKey:@"donation"]];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:followUrl]];
            //NSLog(@"Donation: %@", [_settings objectForKey:@"donation"]);
        }
    }
}


@end
