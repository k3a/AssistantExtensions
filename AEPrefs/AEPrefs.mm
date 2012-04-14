#import <Twitter/Twitter.h>
#import <AppSupport/AppSupport.h>

#import "AEPrefs.h"
#import "AEDonate.h"
#import "AEExtensionCell.h"

// ---------------------------------------------------------------------------------------------------------------------------
#pragma mark - LEGAL CONTROLLER

@implementation AELegalController
- (id)init
{
    if ( (self = [super init]) )
    {
        _view = [[UITextView alloc] initWithFrame:CGRectMake(0,0,320,400)];
        NSString* path = [[NSBundle bundleForClass:[self class]] pathForResource:@"about" ofType:@"txt"];
        _view.text = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        _view.editable = NO;
        
        [[self navigationItem] setTitle:@"About"];
    }
    
    return self;
}
-(void)dealloc
{
    [_view release];
	[super dealloc];
}
- (id) view
{
    return _view;
}
@end

// ---------------------------------------------------------------------------------------------------------------------------
#pragma mark - MAIN CONTROLLER


@implementation CustomAEController

/*- (void)viewWillBecomeVisible:(void *)spec{
	if(spec)
		[self loadFromSpecifier:(PSSpecifier *)spec];
	[super viewWillBecomeVisible:spec];
    
    _settings = [[NSDictionary alloc] initWithContentsOfFile:@PREF_FILE];
    if (_settings)
        NSLog(@"AEP: Preferences loaded.");
    else
        NSLog(@"AEP: Failed to load preferences.");

}*/

-(void)loadExtensions
{
    CPDistributedMessagingCenter *msgCenter = [CPDistributedMessagingCenter centerNamed:@"me.k3a.AssistantExtensions"];
    [_extensions release];
    _extensions = [[[msgCenter sendMessageAndReceiveReplyName:@"AllExtensions" userInfo:nil] objectForKey:@"Extensions"] copy];
}

static id s_inst = nil;
+(id)sharedInstance
{
    return s_inst;
}

- (id)init
{
    if ( (self = [super init]) )
    {
        s_inst = self;
        
        _settings = [[NSMutableDictionary alloc] initWithContentsOfFile:@PREF_FILE];
        if (_settings)
            NSLog(@"AEP: Preferences loaded.");
        else
        {
            NSLog(@"AEP: Failed to load preferences. Creating a new one...");
            _settings = [[NSMutableDictionary alloc] init];
        }
        
        // set defaults
        if (![_settings objectForKey:@"donation"])
            [_settings setObject:@"5" forKey:@"donation"];
        
        _kexik_followed = [[_settings objectForKey:@"followed"] boolValue];
        if (!_kexik_followed)
        {
            // access twitter and check follow status
            ACAccountStore *accountStore = [[[ACAccountStore alloc] init] autorelease];
            ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
            [accountStore requestAccessToAccountsWithType:accountType withCompletionHandler:^(BOOL granted, NSError *error) 
            {
                if(granted) 
                {
                    NSArray *accountsArray = [accountStore accountsWithAccountType:accountType];
                    
                    if ([accountsArray count] > 0) {
                        _twitterAccount = [[accountsArray objectAtIndex:0] retain];
                        NSLog(@"AEP: Got TW");
                        
                        NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:[_twitterAccount username],@"screen_name_a", @"kexik", @"screen_name_b", nil];
                        
                        TWRequest *postRequest = [[TWRequest alloc] initWithURL:[NSURL URLWithString:@"http://api.twitter.com/1/friendships/exists.json"] 
                                                                     parameters:params 
                                                                  requestMethod:TWRequestMethodGET];
                        [postRequest setAccount:_twitterAccount];
                        
                        [postRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) 
                        {
                            if ([urlResponse statusCode] != 200)
                                NSLog(@"AEP: Error TF Friendship Status: %i", [urlResponse statusCode]);
                            else
                            {
                                NSString* status = [[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] autorelease];
                                _kexik_followed = [status isEqualToString:@"true"];
                                if (!_kexik_followed)
                                {
                                    NSLog(@"AEP: TF not followed");
                                    [_tableView reloadData];
                                }
                                else
                                {
                                    //dispatch_async(dispatch_get_main_queue(), ^{
                                        [_tableView reloadData];
                                    //});
                                }
                            }
                        }];
                    }
                }
            }];
        }
        
        // load extension list
        [self loadExtensions];
    }
    
    return self;
}

- (void) dealloc {
    [_tableView release];
    [_settings release];
    [_twitterAccount release];
    [_extensions release];
    [super dealloc];
}

-(void)followSafari
{
    NSString* followUrl = @"https://twitter.com/intent/follow?original_referer=http%3A%2F%2Fae.k3a.me%2F&region=follow_link&screen_name=kexik&source=followbutton&variant=2.0";
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:followUrl]];
}

-(void)saveSettings
{
    if ([_settings writeToFile:@PREF_FILE atomically:YES])
    {
        NSLog(@"AEP: Settings saved");
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("me.k3a.AssistantExtensions/reloadPrefs"), NULL, NULL, false);
    }
    else
        NSLog(@"AEP: Failed to save settings");
}

-(void)setPref:(id)obj forKey:(NSString*)key
{
    [_settings setObject:obj forKey:key];
    [self saveSettings];
}

- (void)follow
{
    if (_twitterAccount)
    {
        NSMutableDictionary *tempDict = [[NSMutableDictionary alloc] init];
        [tempDict setValue:@"kexik" forKey:@"screen_name"];
        [tempDict setValue:@"true" forKey:@"follow"];
        
        TWRequest *postRequest = [[TWRequest alloc] initWithURL:[NSURL URLWithString:@"http://api.twitter.com/1/friendships/create.json"] 
                                                     parameters:tempDict 
                                                  requestMethod:TWRequestMethodPOST];
        
        
        [postRequest setAccount:_twitterAccount];
        
        [postRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
            if ([urlResponse statusCode] != 200)
            {
                NSLog(@"AEP: TF Status: %i", [urlResponse statusCode]);
                [self followSafari];
            }
            else
            {
                NSLog(@"AEP: TF Success");
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Follow" message:@"Thanks!"  delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
                [alert release];
                
                _kexik_followed = YES;
                [_settings setObject:[NSNumber numberWithBool:YES] forKey:@"followed"];
                [self saveSettings];
                [_tableView reloadData];
            }
        }];
    }
    else // old method
        [self followSafari];
}


- (void)setSpecifier:(PSSpecifier *)spec{
	[self loadFromSpecifier:spec];
}

- (void)loadFromSpecifier:(PSSpecifier *)spec{
	_tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, 480-64) style:UITableViewStyleGrouped];
	[_tableView setDelegate:self];
	[_tableView setDataSource:self];

	if ([self respondsToSelector:@selector(navigationItem)])
		[[self navigationItem] setTitle:@"AssistantExtensions"];
}

- (id) view {
	return _tableView;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{	
	return 4;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 1)
        return @"Extensions";
    
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
        return 2;
    else if (section == 1)
        return [_extensions count];
    else if (section == 2)
        return (_kexik_followed || !_twitterAccount)?2:3;
    else if (section == 3)
        return 1;
        
	return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    if (indexPath.section == 0)
        return 45;
    else if (indexPath.section == 2) // links
    {
        if (indexPath.row == 3)
            return 60;
        else
            return 40;
    }
    /*else if (indexPath.section == 2)
    {
        
    }*/
    return 50;
}

-(void)switchChanged:(UISwitch*)sw
{
    if (sw.tag == 0)
        [_settings setObject:[NSNumber numberWithBool:sw.on] forKey:@"enabled"];
    else if (sw.tag == 1)
        [_settings setObject:[NSNumber numberWithBool:sw.on] forKey:@"debugButtons"];

    [self saveSettings];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    CGSize sz = tableView.frame.size;
    
    if (indexPath.section == 0)
    {
        if (indexPath.row == 0)
        {
            static NSString *CellIdentifier = @"EASwitchAlternate";
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil)
            {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
                
                UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
                switchView.tag = 0;
                cell.accessoryView = switchView;
                cell.textLabel.text = @"Enabled";
                [switchView setAlternateColors:YES];
                NSNumber* h = [_settings objectForKey:@"enabled"];
                [switchView setOn:(!h || [h boolValue]) animated:NO];
                [switchView addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
                [switchView release];
            }
        }
        else if (indexPath.row == 1)
        {
            static NSString *CellIdentifier = @"EASwitch";
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil)
            {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
                
                UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
                switchView.tag = 1;
                cell.accessoryView = switchView;
                cell.textLabel.text = @"Debug Buttons";
                NSNumber* h = [_settings objectForKey:@"debugButtons"];
                [switchView setOn:(h && [h boolValue]) animated:NO];
                [switchView addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
                [switchView release];
            }
        }
    }
    else if (indexPath.section == 1)
    {
        static NSString *CellIdentifier = @"EAEx";
        
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) 
        {
            //cell = [[[AEExtensionCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
            
            // load from nib
            if (![[NSBundle bundleForClass:[self class]] loadNibNamed:@"AEExtensionCell" owner:self options:nil])
            {
                NSLog(@"AEP: Warning! Could not load AEExtensionCell nib file.\n");
                return nil;
            }
            cell = _exCell;
        }
    
        [(AEExtensionCell*)cell configureForExtension:[_extensions objectAtIndex:indexPath.row]];
    }
    else if (indexPath.section == 2)
    {
        if (indexPath.row == 0)
        {
            static NSString *CellIdentifier = @"AEWeb";
            
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) 
            {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
                
                UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(8,0,sz.width-35, 35)];
                label.font = [UIFont boldSystemFontOfSize:15];
                label.numberOfLines = 0;
                label.backgroundColor = [UIColor clearColor];
                label.textAlignment = UITextAlignmentCenter;
                label.text = @"Website: http://ae.k3a.me";
                
                [cell.contentView addSubview:label];
                [label release];
            }
        }
        if (indexPath.row == 1)
        {
            static NSString *CellIdentifier = @"AEWeb";
            
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) 
            {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
                
                UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(8,0,sz.width-35, 35)];
                label.font = [UIFont boldSystemFontOfSize:15];
                label.numberOfLines = 0;
                label.backgroundColor = [UIColor clearColor];
                label.textAlignment = UITextAlignmentCenter;
                label.text = @"Support by Donating";
                
                [cell.contentView addSubview:label];
                [label release];
            }
        }
        else if (indexPath.row == 2)
        {
            static NSString *CellIdentifier = @"AEFollow";
            
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) 
            {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
                
                UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(8,0,sz.width-35, 35)];
                label.font = [UIFont boldSystemFontOfSize:15];
                label.numberOfLines = 0;
                label.backgroundColor = [UIColor clearColor];
                label.textColor = [UIColor colorWithRed:.6f green:0 blue:0 alpha:1];
                label.textAlignment = UITextAlignmentCenter;
                label.text = @"Follow me @kexik (not following)";
                
                [cell.contentView addSubview:label];
                [label release];
            }
        }
        else if (indexPath.row == 2)
        {
            static NSString *CellIdentifier = @"AEAdv";
            
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) 
            {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
                
            }
        }
    }
    else if (indexPath.section == 3)
    {
        if (indexPath.row == 0)
        {
            static NSString *CellIdentifier = @"AELegal";
            
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) 
            {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
                
                /*UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(8,0,sz.width-35, 40)];
                label.font = [UIFont systemFontOfSize:15];
                label.numberOfLines = 0;
                label.backgroundColor = [UIColor clearColor];
                label.textAlignment = UITextAlignmentCenter;
                label.text = @"Website: http://ae.k3a.me";
                
                [cell.contentView addSubview:label];
                [label release];*/
                cell.textLabel.text = @"About";
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;//UITableViewCellAccessoryDetailDisclosureButton;
            }
        }
    }
    
    if (!cell)
    {
        static NSString *CellIdentifier = @"EADefaultCell";
        
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) 
        {
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) 
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        }
    }
 
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if (indexPath.section == 1)
    {
        NSString* bundlePath = [[_extensions objectAtIndex:indexPath.row] objectForKey:@"PreferenceBundle"];
        if (!bundlePath) return;
        
        NSBundle* b = [NSBundle bundleWithPath:bundlePath];
        if (!b) return;
        
        if (![b load]) NSLog(@"AEP: Failed to load pref bundle %@!", bundlePath);
        NSString* principal = [b objectForInfoDictionaryKey:@"NSPrincipalClass"];
        Class cls = NSClassFromString(principal);
        if (cls)
        {
            PSViewController* ctrl = [cls new];
            if ([ctrl respondsToSelector:@selector(setParentController)]) [ctrl setParentController:self];
            if ([ctrl respondsToSelector:@selector(setRootController)]) [ctrl setRootController:self.rootController];
            [self pushController:ctrl];
            [ctrl release];
        }
        else
            NSLog(@"AEP: Failed to instantiate prefbundle principal %@", principal);
    }
    else if (indexPath.section == 2)
    {
        if (indexPath.row == 0)
        {
            NSString* followUrl = @"http://ae.k3a.me/";
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:followUrl]];
        }
        else if (indexPath.row == 1)
        {
            AEDonate* ctrl = [[[AEDonate alloc] initWithParent:self settings:_settings] autorelease];
            [self pushController:ctrl];
        }
        else if (indexPath.row == 2)
            [self follow];
    }
    else if (indexPath.section == 3)
        [self pushController: [[[AELegalController alloc] init] autorelease] ];
}


@end
// vim:ft=objc
