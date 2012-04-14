//
//  AEYTASIAuthenticationDialog.h
//  Part of AEYTASIHTTPRequest -> http://allseeing-i.com/AEYTASIHTTPRequest
//
//  Created by Ben Copsey on 21/08/2009.
//  Copyright 2009 All-Seeing Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class AEYTASIHTTPRequest;

typedef enum _ASIAuthenticationType {
	AEYTASIStandardAuthenticationType = 0,
    AEYTASIProxyAuthenticationType = 1
} AEYTASIAuthenticationType;

@interface AEYTASIAutorotatingViewController : UIViewController
@end

@interface AEYTASIAuthenticationDialog : AEYTASIAutorotatingViewController <UIActionSheetDelegate, UITableViewDelegate, UITableViewDataSource> {
	AEYTASIHTTPRequest *request;
	AEYTASIAuthenticationType type;
	UITableView *tableView;
	UIViewController *presentingController;
	BOOL didEnableRotationNotifications;
}
+ (void)presentAuthenticationDialogForRequest:(AEYTASIHTTPRequest *)request;
+ (void)dismiss;

@property (retain) AEYTASIHTTPRequest *request;
@property (assign) AEYTASIAuthenticationType type;
@property (assign) BOOL didEnableRotationNotifications;
@property (retain, nonatomic) UIViewController *presentingController;
@end
