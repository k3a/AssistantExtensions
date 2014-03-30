#import "AERandomSnippet.h"
#import <UIKit/UIKit.h>

@implementation AERandomSnippet
- (id)initWithProperties:(NSDictionary *)props system:(id<SESystem>)system {
	if ((self = [super init])) {
		_view = [[UILabel alloc] initWithFrame:CGRectMake(2, 316, 20, 42)];
		[_view setBackgroundColor:[UIColor clearColor]];
		[_view setText:[props objectForKey:@"number"]];
		[_view setTextAlignment:UITextAlignmentCenter];
		[_view setTextColor:[UIColor whiteColor]];
		[_view setFont:[UIFont systemFontOfSize:42.f]];
	}
	
	return self;
}

- (id)view {
	return _view;
}

- (void)dealloc {
	[_view release];
	[super dealloc];
}
@end
