#import <SpringBoard/SpringBoard.h>

@interface AFConnection : NSObject
- (void)clearContext;
- (void)startSpeechRequest;
- (void)startRequestWithText:(id)arg1 timeout:(double)arg2;
- (void)startRequestWithCorrectedText:(id)arg1 forSpeechIdentifier:(id)arg2;
@end



@interface SBUIController (AEIOS5)
- (void)lockFromSource:(int)fp8;
- (void)_hideKeyboard;
@end

@interface SBAwayController (AEIOS5)
- (BOOL)isDeviceLocked;
@end

@interface SpringBoard (AEIOS5)
- (void)activateAssistantWithOptions:(id)fp8 withCompletion:(id)fp;
@end

@interface ACFakeAssistantController
	-(id)_extraSpace;
	-(void)setSpace:(float)f;
@end


@interface SBAwayView (AEIOS5)
- (void)hideBulletinView;
- (void)showBulletinView;
@end

@interface SBAssistantController : NSObject
+ (SBAssistantController*)sharedInstance;
+ (BOOL)preferenceEnabled; // ios5
+(BOOL)supportedAndEnabled; // ios6
+ (BOOL)shouldEnterAssistant;
-(BOOL)activatePluginForEvent:(int)event; // ios6
-(id)pluginController; //ios6
- (void)dismissAssistant;
- (void)dismissAssistantWithFade:(double)fp8;
- (void)_submitQuery:(id)fp8;
-(AFConnection*)_connection;
- (void)_startProcessingRequest;
-(void)expectsFaceContact;
-(void)_say:(NSString*)what;
-(void)_say:(NSString*)what forced:(BOOL)forced;
@end

@interface SBBrightnessController (AEIOS5)
+ (id)sharedBrightnessController;
- (void)setBrightnessLevel:(float)fp8;
@end

@interface ADCommandCenter : NSObject
+ (id)sharedCommandCenter;
- (id)_locationManager;
@end

@interface ADLocationManager : NSObject
- (id)currentRequestOrigin;
@end

@interface CLLocationManager (AEIOS5)
-(id)initWithEffectiveBundle:(NSBundle*)b;
@end

@interface SBAppSwitcherController : NSObject
+ (id)sharedInstance;
+ (id)sharedInstanceIfAvailable;
- (void)_removeApplicationFromRecents:(id)fp8;
@end

@interface SBAssistantGuideSectionModel : NSObject
{
    NSString *_title;
    NSMutableArray *_phrases;
}

- (id)init;
- (void)dealloc;
- (NSMutableArray*)phrases;
- (void)setPhrases:(NSMutableArray*)fp8;
- (id)title;
- (void)setTitle:(id)fp8;

@end

@interface SBAssistantGuideDomainModel : NSObject
{
    NSString *_name;
    NSString *_tagPhrase;
    NSString *_displayIdentifier;
    NSString *_bundleIdentifier;
    NSMutableArray *_requiredApps;
    NSMutableArray *_requiredCapabilities;
    NSString *_sectionFilename;
    NSMutableArray *_sections;
}

- (id)init;
- (void)dealloc;
- (id)sections;
- (id)sectionFilename;
- (void)setSectionFilename:(id)fp8;
- (id)requiredCapabilities;
- (void)setRequiredCapabilities:(id)fp8;
- (id)requiredApps;
- (void)setRequiredApps:(id)fp8;
- (id)bundleIdentifier;
- (void)setBundleIdentifier:(id)fp8;
- (id)displayIdentifier;
- (void)setDisplayIdentifier:(id)fp8;
- (id)tagPhrase;
- (void)setTagPhrase:(id)fp8;
- (id)name;
- (void)setName:(id)fp8;

@end

@interface SBAssistantGuideDomainListCell : UITableViewCell
{
    id _delegate;
    UIImageView *_iconView;
    UILabel *_tagPhraseLabel;
    UILabel *_domainNameLabel;
    UIImageView *_chevronView;
    UIImageView *_separator;
}

+ (float)rowHeight;
- (id)initWithReuseIdentifier:(id)fp8;
- (void)dealloc;
- (void)setSelected:(BOOL)fp8 animated:(BOOL)fp12;
- (void)setHighlighted:(BOOL)fp8 animated:(BOOL)fp12;
- (void)setDomainName:(id)fp8;
- (void)setTagPhrase:(id)fp8;
- (void)setIconImage:(id)fp8;
- (void)prepareForReuse;
- (void)layoutSubviews;
- (id)delegate;
- (void)setDelegate:(id)fp8;

@end

@interface SBAssistantGuideModel : NSObject
{
    NSMutableArray *_domains;
}

- (id)init;
- (void)dealloc;
- (void)_loadAllDomains;
- (id)allDomains;

@end

//-------------------------------------------------------------------------------

@protocol AceObject <NSObject, NSCopying, NSMutableCopying>
- (id)init;
- (id)initWithDictionary:(id)fp8;
- (id)initWithDictionary:(id)fp8 context:(id)fp12;
- (id)dictionary;
- (id)properties;
- (id)encodedClassName;
- (id)groupIdentifier;
- (id)copyWithZone:(struct _NSZone *)fp8;
- (id)mutableCopyWithZone:(struct _NSZone *)fp8;
@end

@protocol SAAceSerializable <AceObject>
@end

@protocol SADeferredKeyObject <AceObject>
- (id)deferredKeys;
@end

@protocol AceContext <NSObject>
- (id)aceObjectWithDictionary:(id)arg1;
- (Class)classWithClassName:(id)arg1 group:(id)arg2;
@end

@interface BasicAceContext : NSObject <AceContext>
{
    NSMutableDictionary *_groupMap;
    NSMutableDictionary *_objectMap;
}

- (void)addAcronym:(id)arg1 forGroup:(id)arg2;
- (void)addClass:(Class)arg1 forCommand:(id)arg2 inGroup:(id)arg3;
- (id)aceObjectWithDictionary:(id)arg1;
- (Class)classWithClassName:(id)arg1 group:(id)arg2;
- (id)init;
- (void)dealloc;

@end

@interface AceObject : NSObject <AceObject>
{
    NSMutableDictionary *_dict;
    id <AceContext> _context;
}

+ (id)aceObjectWithGenericCommand:(id)arg1 context:(id)arg2;
+ (id)_aceObjectWithMutableDictionary:(id)arg1 context:(id)arg2;
+ (id)aceObjectArrayWithDictionaryArray:(id)arg1 baseClass:(Class)arg2 context:(id)arg3;
+ (id)aceObjectDictionaryWithDictionary:(id)arg1 baseClass:(Class)arg2 context:(id)arg3;
+ (id)aceObjectArrayWithDictionaryArray:(id)arg1 baseProtocol:(id)arg2 context:(id)arg3;
+ (id)aceObjectDictionaryWithDictionary:(id)arg1 baseProtocol:(id)arg2 context:(id)arg3;
+ (id)dictionaryArrayWithAceObjectArray:(id)arg1;
+ (id)dictionaryWithAceObjectDictionary:(id)arg1;
+ (id)newAceObjectWithGenericCommand:(id)arg1 context:(id)arg2;
+ (id)newAceObjectWithDictionary:(id)arg1 context:(id)arg2;
+ (id)_newAceObjectWithMutableDictionary:(id)arg1 context:(id)arg2;
+ (id)aceObjectWithDictionary:(id)arg1 context:(id)arg2;
+ (id)_descriptionOf:(id)arg1 prefix:(id)arg2;
- (void)setProperty:(id)arg1 forKey:(id)arg2;
- (id)propertyForKey:(id)arg1;
- (void)setTopLevelProperty:(id)arg1 forKey:(id)arg2;
- (id)_initWithMutableDictionary:(id)arg1 context:(id)arg2;
- (id)topLevelPropertyForKey:(id)arg1;
- (id)encodedClassName;
- (id)initWithDictionary:(id)arg1 context:(id)arg2;
- (BOOL)isEqual:(id)arg1;
- (unsigned int)hash;
- (id)description;
- (id)copyWithZone:(struct _NSZone *)arg1;
- (id)init;
- (void)dealloc;
- (id)groupIdentifier;
- (id)properties;
- (id)mutableCopyWithZone:(struct _NSZone *)arg1;
- (id)initWithDictionary:(id)arg1;
- (id)context;
- (id)dictionary;

@end

@interface SAUIConfirmationOptions : AceObject <SAAceSerializable>
{
}

+ (id)confirmationOptionsWithDictionary:(id)arg1 context:(id)arg2;
+ (id)confirmationOptions;
@property(copy, nonatomic) NSArray *cancelCommands;
@property(copy, nonatomic) NSString *cancelLabel;
@property(copy, nonatomic) NSString *cancelTrigger;
@property(copy, nonatomic) NSArray *confirmCommands;
@property(copy, nonatomic) NSString *confirmText;
@property(copy, nonatomic) NSArray *denyCommands;
@property(copy, nonatomic) NSString *denyText;
@property(copy, nonatomic) NSArray *submitCommands;
@property(copy, nonatomic) NSString *submitLabel;
- (id)encodedClassName;
- (id)groupIdentifier;

@end

@interface SAAceView : AceObject <SAAceSerializable, SADeferredKeyObject>
{
}

+ (id)aceView;
+ (id)aceViewWithDictionary:(id)arg1 context:(id)arg2;
@property(retain, nonatomic) NSNumber *listenAfterSpeaking;
@property(copy, nonatomic) NSString *speakableText;
@property(copy, nonatomic) NSString *viewId;
- (id)deferredKeys;
- (id)encodedClassName;
- (id)groupIdentifier;

@end

@interface SAUISnippet : SAAceView
{
}

+ (id)snippetWithDictionary:(id)arg1 context:(id)arg2;
+ (id)snippet;
@property(retain, nonatomic) SAUIConfirmationOptions *confirmationOptions;
@property(copy, nonatomic) NSArray *otherOptions;
- (id)encodedClassName;
- (id)groupIdentifier;

@end


@protocol AFUISnippetDelegate;

@interface AFUISnippetController : NSObject
{
    id <AFUISnippetDelegate> _delegate;
    int _phase;
}

- (id)init;
- (void)dealloc;
- (void)viewDidDisappear;
- (void)viewWillDisappear;
- (void)viewWillAppear;
- (void)viewDidAppear;
- (id)parentViewController;
@property(readonly, nonatomic) UIView *view;
- (void)setPhase:(int)arg1;
- (int)phase;
@property(readonly, nonatomic) id <AFUISnippetDelegate> delegate; // @synthesize delegate=_delegate;
- (id)initWithAceObject:(id)arg1 delegate:(id)arg2;
- (id)speakableTextForLanguageCode:(id)arg1;
- (BOOL)wantsConfirmationTossBehavior;
- (BOOL)_presentationShouldAnimate;
- (BOOL)_wantsFullWidthOfScreen;
- (BOOL)_wantsUnmodifiedHeight;
- (BOOL)_wantsStaticPresentation;
- (BOOL)_isServerResponse;
- (BOOL)_supportsReload;
- (BOOL)_affectsMagicPocket;
- (void)_reloadWithAceObject:(id)arg1;
- (void)assistantInterrupted;
- (void)markWithStamp:(int)arg1;
- (void)setIsLastInTranscript:(BOOL)arg1;

@end

@interface ADSession : NSObject

@end



