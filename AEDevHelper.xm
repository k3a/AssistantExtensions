#import "shared.h"
#import "AESpringBoardMsgCenter.h"

@interface AEAssistantViewHelper : NSObject
@end
@implementation AEAssistantViewHelper

-(void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if(buttonIndex == 1)
	{
		NSString* text = [[alertView textFieldAtIndex:0] text];
        if (text && [text length])
        {
            IPCCall(@"me.k3a.AssistantExtensions", @"ActivateAssistant", nil);
            IPCCall(@"me.k3a.AssistantExtensions", @"SubmitQuery", [NSDictionary dictionaryWithObjectsAndKeys:text,@"query",nil]);
        }
	}
}

-(void)hideTapped
{
	IPCCall(@"me.k3a.AssistantExtensions", @"DismissAssistant", nil);
}

-(void)queryTapped
{
	UIAlertView* dialog = [[UIAlertView alloc] initWithTitle:@"Enter Query" message:@"" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK",nil]; 
    [dialog setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [dialog show];
    [dialog release];
}

@end

static AEAssistantViewHelper* s_aeHelper = nil;

%hook SBAssistantView

- (id)initWithFrame:(struct CGRect)rect
{
	id ret = %orig;

	if (!s_aeHelper) s_aeHelper = [AEAssistantViewHelper new];
    
    NSNumber* debugButtons = [[AESpringBoardMsgCenter sharedInstance] prefForKey:@"debugButtons"];
    
    if (debugButtons && [debugButtons boolValue])
    {
        UIView* _contentView = nil;
        object_getInstanceVariable(self, "_contentView", (void**)&_contentView);

        UIButton* btnHide = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [btnHide setFrame:CGRectMake(20,440, 50, 32)];
        [btnHide setTitle:@"Hide" forState:UIControlStateNormal];
        [btnHide addTarget:s_aeHelper action:@selector(hideTapped) forControlEvents:UIControlEventTouchUpInside];
        [_contentView addSubview:btnHide];

        UIButton* btnQuery = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [btnQuery setFrame:CGRectMake(20,400, 50, 32)];
        [btnQuery setTitle:@"Query" forState:UIControlStateNormal];
        [btnQuery addTarget:s_aeHelper action:@selector(queryTapped) forControlEvents:UIControlEventTouchUpInside];
        [_contentView addSubview:btnQuery];
    }

	return ret;
}

%end

