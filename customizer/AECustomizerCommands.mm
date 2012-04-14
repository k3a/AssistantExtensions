#import "AECustomizerCommands.h"

@implementation AECustomizerCommands

-(id)init {
	if ( (self = [super init]) ) {
		// additional initialization
	}
	return self;
}

-(BOOL)handleSpeech:(NSString*)text tokens:(NSArray*)tokens tokenSet:(NSSet*)tokenset context:(id<SEContext>)ctx {
	NSArray *pref = [NSArray arrayWithContentsOfFile:@"/var/mobile/Library/Preferences/me.k3a.ae.customizer.plist"];
	NSMutableArray *views = [NSMutableArray array];
	
	for (NSDictionary *dict in pref) {
		NSString *get = [dict objectForKey:@"get"];
		NSString *put = [dict objectForKey:@"put"];
		if (!get || !put) continue;
		
		NSLog(@"[AECustomizer] %@ %@", get, put);
		NSLog(@"[AECustomizer] %@ %@", [text lowercaseString], [get lowercaseString]);
		
		if ([[text lowercaseString] isEqualToString:[get lowercaseString]]) {
			NSLog(@"[AECustomizer] We are the same <3");
			[views addObject:[ctx createAssistantUtteranceView:put]];
			
			[ctx sendAddViews:views];
			[ctx sendRequestCompleted];
			return YES;
		}
	}
	
	return NO;
}

@end
// vim:ft=objc
