//
//  AEExtensionCell.m
//  AEPrefs
//
//  Created by K3A on 3/23/12.
//  Copyright (c) 2012 K3A. All rights reserved.
//

#import "AEExtensionCell.h"
#import "AEPrefs.h"

@implementation AEExtensionCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) 
    {
        
        
    }
    return self;
}

-(void)dealloc
{
    [_ident release];
    [super dealloc];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)configureForExtension:(NSDictionary*)exdict;
{
    BOOL hasPrefs = [[exdict objectForKey:@"HasPreferenceBundle"] boolValue];
    
    //_vNext.hidden = !pref;
    self.accessoryType = hasPrefs?UITableViewCellAccessoryDisclosureIndicator:UITableViewCellAccessoryNone;
    
    NSString* verStr = [exdict objectForKey:@"Version"];
    _lblName.text = [NSString stringWithFormat:@"%@ %@", [exdict objectForKey:@"DisplayName"], verStr];
    _lblDesc.text = [exdict objectForKey:@"Description"];
    
    [_ident release];
    _ident = [[exdict objectForKey:@"Identifier"] copy];
    //NSLog(@"IDENT '%@'", _ident);
    
    NSNumber* enabled = [exdict objectForKey:@"Enabled"];
    _switch.on = !enabled || [enabled boolValue];
                        
    NSString* author = [exdict objectForKey:@"Author"];
    NSString* website = [exdict objectForKey:@"Website"];
    if (!author) author = @"";
    if (!website) website = @"";
                    
    _lblAuthor.text = [NSString stringWithFormat:@"%@ %@",author,website];
    
    // load icon
    UIImage* imgIcon = [UIImage imageWithContentsOfFile:[exdict objectForKey:@"IconPath"]];
    _icon.image = imgIcon;
    
    if (!_icon.image) // default icon
        _icon.image = [UIImage imageWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"DefaultIcon" ofType:@"png"]];
}

-(IBAction)enabledStateChanged:(UISwitch*)sender
{
    CustomAEController* ctrl = [CustomAEController sharedInstance];
    [ctrl setPref:[NSNumber numberWithBool:sender.on] forKey:_ident];
    [ctrl saveSettings];
}

-(void)setRootController:(id)pff
{
    // nothing, keep for Preferences framework
}

-(void)setParentController:(id)pff
{
    // nothing, keep for Preferences framework
}

@end
