#import <Preferences/PSListController.h>
#import <Preferences/PSEditableListController.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSTextFieldSpecifier.h>

#define PLIST_PATH "/var/mobile/Library/Preferences/me.k3a.ae.customizer.plist"
static BOOL stopIt = NO;

static NSUInteger GetIndexForSpec(PSListController *list, PSSpecifier *spec) {
	NSUInteger index = (NSUInteger)[list indexOfSpecifier:spec];
	
	if 		((index-1)%3 == 0) { NSLog(@"asdf %i", (index-1)/3); return (index-1)/3; }
	else if ((index-2)%3 == 0) { NSLog(@"asdf %i", (index-2)/3); return (index-2)/3; }
	
	return index;
}

static NSString *StringForSpecifier(NSUInteger index, NSString *key) {
	NSArray *arr = [NSArray arrayWithContentsOfFile:@PLIST_PATH];
	if (!arr) arr = [NSMutableArray array];
	return index<[arr count] ? [[arr objectAtIndex:index] objectForKey:key] : nil;
}

static void SetStringForSpecifier(NSUInteger index, NSString *str, NSString *key) {
	NSMutableArray *arr = [NSMutableArray arrayWithContentsOfFile:@PLIST_PATH];
	if (!arr) arr = [NSMutableArray array];
	BOOL big = index<[arr count];
	
	NSMutableDictionary *place = big ? [arr objectAtIndex:index] : [NSMutableDictionary dictionary];
	[place setObject:str forKey:key];
	
	if (big) [arr replaceObjectAtIndex:index withObject:place];
	else	 [arr addObject:place];
	
	[arr writeToFile:@PLIST_PATH atomically:YES];
}

static NSArray *AddNewSpecifiers(PSListController *ctrl, BOOL first) {
	NSMutableArray *a = [NSMutableArray array];
	
	PSSpecifier *e_group = [PSSpecifier emptyGroupSpecifier];
	PSTextFieldSpecifier *gspec = [PSTextFieldSpecifier preferenceSpecifierNamed:[NSString string]
											   target:ctrl
											   set:@selector(setGetString:forSpec:)
											   get:@selector(getStringForSpec:)
											   detail:Nil
											   cell:PSEditTextCell
											   edit:Nil];
	PSTextFieldSpecifier *pspec = [PSTextFieldSpecifier preferenceSpecifierNamed:[NSString string]
											   target:ctrl
											   set:@selector(setPutString:forSpec:)
											   get:@selector(putStringForSpec:)
											   detail:Nil
											   cell:PSEditTextCell
											   edit:Nil];
	
	[gspec setPlaceholder:@"Input"];
	[pspec setPlaceholder:@"Output"];
	
	if (first) {
		[a addObject:e_group];
		[a addObject:gspec];
		[a addObject:pspec];
		[ctrl addSpecifiersFromArray:a animated:YES];
	}
	
	else {
		[ctrl insertSpecifier:e_group atIndex:[[ctrl specifiers] count]-2 animated:YES];
		[ctrl insertSpecifier:gspec atIndex:[[ctrl specifiers] count]-2 animated:YES];
		[ctrl insertSpecifier:pspec atIndex:[[ctrl specifiers] count]-2 animated:YES];
	}
	
	return a;
}

@interface AECustomizerPreferencesListController : PSListController {
	BOOL shallDel;
}

- (NSArray *)loadSpecifiers;
- (void)addNewSpecifiers;
@end

@implementation AECustomizerPreferencesListController
- (id)specifiers {
	NSLog(@"GETTING DA SPECIFIERZ");
	
	UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStylePlain target:self action:@selector(addNewSpecifiers)];
	[[self navigationItem] setRightBarButtonItem:editButton];
	
	if (_specifiers == nil) {
		_specifiers = [[self loadSpecifiers] retain];
	}
	return _specifiers;
}

- (NSArray *)loadSpecifiers {
	NSMutableArray *spec = [NSMutableArray array];
	
	NSMutableArray *arr = [NSMutableArray arrayWithContentsOfFile:@PLIST_PATH];
	if (!arr) arr = [NSMutableArray array];
	if (![arr count] > 0) {
		[arr addObject:[NSDictionary dictionary]];
		[arr writeToFile:@PLIST_PATH atomically:YES];
	}
	
	// TODO: Use NSEnumerator
	for (NSUInteger i=0; i<[arr count]; i++) {
		NSArray *a = AddNewSpecifiers(self, YES);
		[spec addObjectsFromArray:a];
	}
	
	PSSpecifier *e_group = [PSSpecifier emptyGroupSpecifier];
	PSSpecifier *btn = [PSSpecifier preferenceSpecifierNamed:@"Reset"
									  target:self
									  set:nil
					       			  get:nil
									  detail:Nil
									  cell:PSButtonCell
									  edit:Nil];
	btn->action = @selector(getRidOfEverything);
	
	[spec addObject:e_group];
	[spec addObject:btn];
	
	return spec;
}

- (NSString *)getStringForSpec:(PSSpecifier *)spec {
	return StringForSpecifier(GetIndexForSpec(self, spec), @"get");
}

- (NSString *)putStringForSpec:(PSSpecifier *)spec {
	return StringForSpecifier(GetIndexForSpec(self, spec), @"put");
}

- (void)setGetString:(NSString *)str forSpec:(PSSpecifier *)spec {
	[self setPreferenceValue:str specifier:spec];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	SetStringForSpecifier(GetIndexForSpec(self, spec), str, @"get");
}

- (void)setPutString:(NSString *)str forSpec:(PSSpecifier *)spec {
	[self setPreferenceValue:str specifier:spec];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	SetStringForSpecifier(GetIndexForSpec(self, spec), str, @"put");
}

- (void)getRidOfEverything {
	NSArray *clear = [NSArray array];
	[clear writeToFile:@PLIST_PATH atomically:YES];
	
	[[self navigationController] popViewControllerAnimated:YES];
}

- (void)addNewSpecifiers {
	NSLog(@"ADD BUTTON! :D");
	AddNewSpecifiers(self, NO);
}
@end

// vim:ft=objc
