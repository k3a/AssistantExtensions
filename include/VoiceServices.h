#import  <Foundation/Foundation.h>

@interface VSSpeechSynthesizer : NSObject 
{ 
} 
+ (id)availableVoices;
+ (id)availableVoicesForLanguageCode:(id)fp8;
+ (id)availableLanguageCodes; 
+ (BOOL)isSystemSpeaking; 
- (id)startSpeakingString:(id)string; 
- (id)startSpeakingString:(id)arg1 withLanguageCode:(id)arg2;
- (id)startSpeakingString:(id)string toURL:(id)url; 
- (id)startSpeakingString:(id)string toURL:(id)url withLanguageCode:(id)code; 
- (float)rate;             // default rate: 1 
- (id)setRate:(float)rate; 
- (float)pitch;           // default pitch: 0.5
- (id)setPitch:(float)pitch; 
- (void)setVoice:(id)fp8;
- (id)voice;
- (float)volume;       // default volume: 0.8
- (id)setVolume:(float)volume; 

- (id)pauseSpeakingAtNextBoundary:(int)fp8;
- (id)pauseSpeakingAtNextBoundary:(int)fp8 synchronously:(BOOL)fp12;
- (id)continueSpeaking;

@end