//
//  AEDonate.h
//  AEPrefs
//
//  Created by K3A on 3/20/12.
//  Copyright (c) 2012 K3A. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Preferences/PSViewController.h>

@class CustomAEController;

@interface AEDonate: PSViewController <UITextFieldDelegate,UITableViewDataSource,UITableViewDelegate> {
    UITableView* _tableView;
    NSMutableDictionary *_settings;
    CustomAEController* _parent;
}
-(id)initWithParent:(CustomAEController*)parent settings:(NSMutableDictionary*)settings;
-(id)view;
@end