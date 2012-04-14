//
//  AEExtensionCell.h
//  AEPrefs
//
//  Created by K3A on 3/23/12.
//  Copyright (c) 2012 K3A. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface AEExtensionCell : UITableViewCell {
    
    IBOutlet UILabel* _lblName;
    IBOutlet UIView* _vNext;
    IBOutlet UILabel* _lblDesc;
    IBOutlet UILabel* _lblAuthor;
    IBOutlet UIImageView* _icon;
    IBOutlet UISwitch* _switch;
    
    NSString* _ident;
}

-(void)configureForExtension:(NSDictionary*)exdict;

@end
