//
//  SnippetExtensionController.h
//  SnippetExtension
//
//  Created by K3A on 12/18/11.
//  Copyright (c) 2011 K3A.me. All rights reserved.
//

#import <UIKit/UIKit.h>


/*
 @interface AceObject {
     @"NSMutableDictionary" _dict;
     @"<AceContext>" _context;
 }
 -(@)dictionary;
 -(@)context;
 -(@)initWithDictionary:(@)a1 ;
 -(@)mutableCopyWithZone:(^{_NSZone=})a1 ;
 -(@)properties;
 -(@)groupIdentifier;
 -(v)dealloc;
 -(@)init;
 -(@)copyWithZone:(^{_NSZone=})a1 ;
 -(@)description;
 -(I)hash;
 -(c)isEqual:(@)a1 ;
 -(@)initWithDictionary:(@)a1 context:(@)a2 ;
 -(@)encodedClassName;
 -(@)topLevelPropertyForKey:(@)a1 ;
 -(@)_initWithMutableDictionary:(@)a1 context:(@)a2 ;
 -(v)setTopLevelProperty:(@)a1 forKey:(@)a2 ;
 -(@)propertyForKey:(@)a1 ;
 -(v)setProperty:(@)a1 forKey:(@)a2 ;
 @end
 
 */

/*
 @interface NotesAssistantNoteUpdate : NSObject <AFServiceCommand>
 {
 NoteContext *_noteContext;
 NoteObject *_note;
 }
 
 - (void)setNoteContext:(id)fp8;
 - (void).cxx_destruct;
 - (void)performWithCompletion:(id)fp(null);
 - (id)_updateNote;
 - (id)_validate;
 - (id)noteContext;
 
 @end
 */

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
 
 /*
 
 @interface AFUISnippetView : UIView
 {
     id <AFUISnippetViewDelegate> _delegate;
     AFUISnippetContentContainerView *_contentContainer;
     UIView *_shadowView;
     UIImageView *_bottomGradientImage;
     BOOL _hasDisclosure;
     BOOL _isDisclosed;
     int _backgroundStyle;
 }
 
 + (void)layoutShadowView:(id)arg1 withinBounds:(struct CGRect)arg2;
 + (id)addShadowToView:(id)arg1;
 - (void)dealloc;
 - (int)backgroundStyle;
 - (void)setBackgroundStyle:(int)arg1;
 @property(nonatomic) int borderStyle;
 @property(retain, nonatomic) UIView *backgroundView;
 @property(retain, nonatomic) UIView *contentView;
 @property(nonatomic) id <AFUISnippetViewDelegate> delegate; // @synthesize delegate=_delegate;
 - (struct CGSize)sizeThatFits:(struct CGSize)arg1;
 - (void)layoutSubviews;
 - (id)initWithFrame:(struct CGRect)arg1;
 @property(nonatomic) BOOL showsShadow;
 @property(nonatomic) BOOL hasDisclosure; // @synthesize hasDisclosure=_hasDisclosure;
 @property(nonatomic, getter=isDisclosed) BOOL disclosed; // @synthesize disclosed=_isDisclosed;
 - (void)setHeaderText:(id)arg1;
 - (void)setHeaderImage:(id)arg1;
 - (void)_disclosureButtonHit:(id)arg1;
 - (void)_resizeToFit;
 - (void)_setDisclosed:(BOOL)arg1;
 
 @end*/
 


//AFUISnippetView
//AFUISnippetPaperView paper :)
//AFUIUtteranceView has bubbles
//AFUISystemSnippetController

@class AFUISnippetController;

@interface HelloSnippetController : AFUISnippetController {
    UIView* _view;
}

- (id)view;
- (void)dealloc;
- (id)initWithAceObject:(id)ace delegate:(id)dlg;

@end
