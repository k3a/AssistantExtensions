//
//  AEPrefs.h
//  AEPrefs
//
//  Created by K3A on 3/20/12.
//  Copyright (c) 2012 K3A. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Preferences/Preferences.h>
#import <Accounts/Accounts.h>

#define PREF_FILE "/var/mobile/Library/Preferences/me.k3a.AssistantExtensions.plist"

@interface AELegalController: PSViewController {
    UITextView* _view;
}
- (id) view;
@end


@interface CustomAEController: PSViewController <UITextFieldDelegate,UITableViewDataSource,UITableViewDelegate> {
    
    IBOutlet UITableViewCell* _exCell;
    
    UITableView *_tableView;
    NSMutableDictionary *_settings;
    BOOL _kexik_followed;
    ACAccount* _twitterAccount;
    
    NSMutableArray* _extensions;
}
+(id)sharedInstance;
-(id)view;
-(void)dealloc;
-(void)loadFromSpecifier:(PSSpecifier *)spec;
-(void)setSpecifier:(PSSpecifier *)spec;
-(void)saveSettings;
-(void)setPref:(id)obj forKey:(NSString*)key;

@end


@interface UISwitch (K3ASEAdditions)
- (void)setAlternateColors:(BOOL)alternateColors;
@end