#import "SiriObjects.h"

@interface AESBSTogglesCommands : NSObject<SECommand>

-(BOOL)handleSpeech:(NSString*)text tokens:(NSArray*)tokens tokenSet:(NSSet*)tokenset context:(id<SEContext>)ctx;

@end
// vim:ft=objc
