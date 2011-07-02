/*
 
 BSD License
 
 Growler for Google Notifier
 
 Copyright (c) 2005-2011
 Jesper (waffle software)
 googlegrowl@wafflesoftware.net
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice,
 this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 * Neither the name of Growler for Google Notifier or waffle software,
 nor the names of Growler for Google Notifier's contributors may be used to
 endorse or promote products derived from this software without specific
 prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
 BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
 OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 Gmail, Google Mail, Google Calendar and Google are owned by Google, Inc.
 Growl is owned by the Growl Development Team.
 Likewise, the logos of those services are owned and copyrighted to their owners.
 No ownership of any of these is assumed or implied, and no infringement is intended.
 
 For more info on this products or on the technologies on which it builds: 
 Growl: <http://growl.info/>
 Gmail: <http://gmail.com>
 Gmail Notifier: <http://toolbar.google.com/gmail-helper/index.html>
 
 Growler for Google Notifier: <http://wafflesoftware.net/googlegrowl/>
 
 */

//
//  PrefsController.m
//  GMNGrowl
//
//  Created by Jesper on 2005-09-28.
//

#import "PrefsController.h"
#import "GGPluginProtocol.h"

#define		GMNGrowlNotificationFormatTag		2010
#define		GMNGrowlNotificationFormatTextTag	2020
#define		GMNGrowlDontUseABIconsTag			2050
#define		GMNGrowlDontShowOnClickTag			2060
#define		GMNGrowlShowInWhichBrowserTag		2070
#define		GMNGrowlMaxNotificationsCapTag		2090

#define		GMNGrowlEventNotificationFormatTag		2110
#define		GMNGrowlEventNotificationFormatTextTag	2120
#define		GMNGrowlEventDontShowOnClickTag			2160
#define		GMNGrowlEventShowInWhichBrowserTag		2170
#define		GMNGrowlEventMaxNotificationsCapTag		2190

#define		GMNGrowlDisabledTag					3000

#define		GMNGrowlMailEnabledTag				4010
#define		GMNGrowlEventEnabledTag				4020

#define		GMNGrowlLookupNumber(x)				[NSNumber numberWithInt:x]

#define		GMNGrowlLookupDict					[NSDictionary dictionaryWithObjectsAndKeys:\
	GMNGrowlNotificationFormatUDK, GMNGrowlLookupNumber(GMNGrowlNotificationFormatTag),\
	GMNGrowlNotificationTextFormatUDK, GMNGrowlLookupNumber(GMNGrowlNotificationFormatTextTag),\
	GMNGrowlDontUseABIconsUDK, GMNGrowlLookupNumber(GMNGrowlDontUseABIconsTag),\
	GMNGrowlDontShowOnClickUDK, GMNGrowlLookupNumber(GMNGrowlDontShowOnClickTag),\
	GMNGrowlMaxNotificationsCapUDK, GMNGrowlLookupNumber(GMNGrowlMaxNotificationsCapTag),\
	GMNGrowlShowInWhichBrowserUDK, GMNGrowlLookupNumber(GMNGrowlShowInWhichBrowserTag),\
	\
	GMNGrowlEventNotificationFormatUDK, GMNGrowlLookupNumber(GMNGrowlEventNotificationFormatTag),\
	GMNGrowlEventNotificationTextFormatUDK, GMNGrowlLookupNumber(GMNGrowlEventNotificationFormatTextTag),\
	GMNGrowlEventDontShowOnClickUDK, GMNGrowlLookupNumber(GMNGrowlEventDontShowOnClickTag),\
	GMNGrowlEventMaxNotificationsCapUDKUDK, GMNGrowlLookupNumber(GMNGrowlEventMaxNotificationsCapTag),\
	GMNGrowlEventShowInWhichBrowserUDK, GMNGrowlLookupNumber(GMNGrowlEventShowInWhichBrowserTag),\
	\
	\
	GMNGrowlEventEnabledUDK, GMNGrowlLookupNumber(GMNGrowlEventEnabledTag),\
	GMNGrowlMailEnabledUDK, GMNGrowlLookupNumber(GMNGrowlMailEnabledTag),\
	nil]

#define		GMNGrowlAllMailPlaceholders				MAKEPLACEHOLDER(GmailMessageDictAuthorEmailKey), MAKEPLACEHOLDER(GmailMessageDictAuthorNameKey), MAKEPLACEHOLDER(GmailMessageDictTitleKey), MAKEPLACEHOLDER(GmailMessageDictSummaryKey), MAKEPLACEHOLDER(GmailMessageDictDateIssuedKey), MAKEPLACEHOLDER(GmailMessageDictDateModifiedKey) 

#define		GMNGrowlMailPlaceholders				[NSArray arrayWithObjects: GMNGrowlAllMailPlaceholders, nil]

#define		GMNGrowlAllEventPlaceholders				MAKEPLACEHOLDER(GCalEventDictAuthorEmailKey), MAKEPLACEHOLDER(GCalEventDictAuthorNameKey), MAKEPLACEHOLDER(GCalEventDictDateIssuedKey), MAKEPLACEHOLDER(GCalEventDictDateModifiedKey), MAKEPLACEHOLDER(GCalEventDictTitleKey), MAKEPLACEHOLDER(GCalEventDictEventStatusKey), MAKEPLACEHOLDER(GCalEventDictWhereKey), MAKEPLACEHOLDER(GCalEventDictSummaryKey), MAKEPLACEHOLDER(GCalEventAutoEventTimeKey), MAKEPLACEHOLDER(GCalEventAutoWhereSummaryKey), MAKEPLACEHOLDER(GCalEventAutoSummaryWhereKey)

#define		GMNGrowlEventPlaceholders				[NSArray arrayWithObjects: GMNGrowlAllEventPlaceholders, nil]

#define		GMNCFReleaseUnlessNull(x)	{ if (x != NULL) CFRelease(x); }

@implementation PrefsController

static int CompareBundleIDAppDisplayNames(id a, id b, void *context) {
	
	NSURL* appURLa = nil;
	NSURL* appURLb = nil;
	
	if ((LSFindApplicationForInfo(kLSUnknownCreator, (CFStringRef)a, NULL, NULL, (CFURLRef*)&appURLa) == noErr) &&
		(LSFindApplicationForInfo(kLSUnknownCreator, (CFStringRef)b, NULL, NULL, (CFURLRef*)&appURLb) == noErr)) {
		NSString *aName = [[NSFileManager defaultManager] displayNameAtPath:[appURLa path]];
		NSString *bName = [[NSFileManager defaultManager] displayNameAtPath:[appURLb path]];
		
		return [aName compare:bName];
	}
	
	return NSOrderedSame;
	
}

- (IBAction)doUninstall:(id)sender {
	
}

+ (PrefsController *)sharedPreferencesWindowController {
	static PrefsController *_sharedPreferencesWindowController = nil;
	if (!_sharedPreferencesWindowController) {
		_sharedPreferencesWindowController = [[self alloc] initWithWindowNibName:@"Preferences"];
	}
	return _sharedPreferencesWindowController;
}

- (IBAction)launchGrowlPrefPane:(id)sender {
	NSArray *lookThrough = [NSArray arrayWithObjects:@"/Library/PreferencePanes/Growl.prefPane", @"~/Library/PreferencePanes/Growl.prefPane", @"/System/Library/PreferencePanes/Growl.prefPane", @"/Network/Library/PreferencePanes/Growl.prefPane", nil];
	NSEnumerator *pathEnumerator = [lookThrough objectEnumerator];
	NSString *path;
	while (path = [pathEnumerator nextObject]) {
		BOOL isDir;
		path = [path stringByExpandingTildeInPath];
		if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir) {
			[[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:path]];
			return;
		}
	} 
	NSBeep();
}

- (void)openURL:(NSURL *)url {
	[[NSWorkspace sharedWorkspace] openURL:url];
}

- (IBAction)websiteClicked:(id)sender {
	[self openURL:[NSURL URLWithString:@"http://wafflesoftware.net/googlegrowl/"]];
}

- (IBAction)relatedWebsiteClicked:(id)sender {
	switch ([sender tag]) {
		case 1000:
			[self openURL:[NSURL URLWithString:@"http://www.gmail.com/"]];
			break;
		case 1050:
			[self openURL:[NSURL URLWithString:@"http://calendar.google.com/"]];
			break;
		case 2000:
			[self openURL:[NSURL URLWithString:@"http://toolbar.google.com/gmail-helper/"]];
			break;
		case 3000:
			[self openURL:[NSURL URLWithString:@"http://growl.info/"]];
			break;
	}
}

- (void) awakeFromNib {

	NSBundle *gg = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"GoogleGrowl" ofType:@"plugin" inDirectory:@"GoogleGrowl"]];
	[gg load];
	Class ggClass = [gg principalClass];
	[ggClass performSelector:@selector(setIsRunningFromUtility)];
	[ggClass pluginLoaded];
	ggForTesting = [[ggClass alloc] init];
//	//NSLog(@"gg: %@", ggForTesting);
	
//	[titleFormatToken setTokenizingCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@""]];
	[titleFormatToken sendActionOn:(NSLeftMouseDownMask | NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask)];
	[[titleFormatToken cell] setWraps:NO];
	
	[bodyFormatToken setTokenizingCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@""]];
	[bodyFormatToken sendActionOn:(NSLeftMouseDownMask | NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask)];
	[[bodyFormatToken cell] setWraps:NO];

	
	[eventTitleFormatToken setTokenizingCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@""]];
	[eventTitleFormatToken sendActionOn:(NSLeftMouseDownMask | NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask)];
	[[eventTitleFormatToken cell] setWraps:NO];
	
	[eventBodyFormatToken setTokenizingCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@""]];
	[eventBodyFormatToken sendActionOn:(NSLeftMouseDownMask | NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask)];
	[[eventBodyFormatToken cell] setWraps:NO];
	
	[templatesToken setTokenizingCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@""]];
	[[templatesToken cell] setWraps:YES];
	[templatesToken setFrame:[templatesResizeTo frame]];
	[templatesToken setAutoresizingMask:[templatesResizeTo autoresizingMask]];
	
	[templatesToken setBezeled:NO];
	[templatesToken setBordered:NO];
	[templatesToken setBackgroundColor:[NSColor clearColor]];
	[templatesToken setDrawsBackground:NO];
	[templatesToken setEditable:NO];
	[templatesToken setSelectable:YES];
	[templatesToken setFocusRingType:NSFocusRingTypeNone];
	[templatesToken setObjectValue:GMNGrowlMailPlaceholders];
	
	[eventTemplatesToken setTokenizingCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@""]];
	[[eventTemplatesToken cell] setWraps:YES];
	[eventTemplatesToken setFrame:[eventTemplatesResizeTo frame]];
	[eventTemplatesToken setAutoresizingMask:[eventTemplatesResizeTo autoresizingMask]];
	
	[eventTemplatesToken setBezeled:NO];
	[eventTemplatesToken setBordered:NO];
	[eventTemplatesToken setBackgroundColor:[NSColor clearColor]];
	[eventTemplatesToken setDrawsBackground:NO];
	[eventTemplatesToken setEditable:NO];
	[eventTemplatesToken setSelectable:YES];
	[eventTemplatesToken setFocusRingType:NSFocusRingTypeNone];
	[eventTemplatesToken setObjectValue:GMNGrowlEventPlaceholders];
	
	
	[self updateFields];
	[self constructBrowserMenu];
	[NSTimer scheduledTimerWithTimeInterval:40.0 target:self selector:@selector(constructBrowserMenu) userInfo:nil repeats:YES];
	
	//NSLog(@"prefsView: %@", prefsView);
	
//	[self showWindow:nil];
}

- (IBAction)previewEventNotification:(id)sender {
	NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:
		@"example@example.com", GCalEventDictAuthorEmailKey,
		@"John Doe", GCalEventDictAuthorNameKey,
		@"confirmed", GCalEventDictEventStatusKey,
		@"http://example.com/", GCalEventDictEventUUIDKey,
		[NSDate date], GCalEventDictDateIssuedKey,
		[NSDate date], GCalEventDictDateModifiedKey,
		@"http://example.com/", GCalEventDictLinkKey,
		[NSDate date], GCalEventDictNotifyTimeKey,
		[NSDate date], GCalEventDictStartTimeKey,
		[[NSDate date] addTimeInterval:60.0*60.0], GCalEventDictStopTimeKey,
		@"Lorem ipsum summary", GCalEventDictSummaryKey,
		@"Testing events (title)", GCalEventDictTitleKey,
		@"Location", GCalEventDictWhereKey,
		nil];
	[ggForTesting newMessagesReceived:[NSArray arrayWithObject:event] fullCount:1];
//	//NSLog(@"preview event notification");
}
- (IBAction)previewMailNotification:(id)sender {
	NSDictionary *mail = [NSDictionary dictionaryWithObjectsAndKeys:
		@"example@example.com", GmailMessageDictAuthorEmailKey,
		@"John Doe", GmailMessageDictAuthorNameKey,
		@"http://example.com/", GmailMessageDictMailUUIDKey,
		[NSDate date], GmailMessageDictDateIssuedKey,
		[NSDate date], GmailMessageDictDateModifiedKey,
		@"http://example.com/", GmailMessageDictLinkKey,
		@"Mail Text", GmailMessageDictSummaryKey,
		@"Mail Subject", GmailMessageDictTitleKey,
		nil];
	[ggForTesting newMessagesReceived:[NSArray arrayWithObject:mail] fullCount:1];
//	//NSLog(@"preview mail notification");
}

- (void)controlTextDidChange:(NSNotification *)aNotification {
	[self prefsChanged:titleFormatToken];
	[self prefsChanged:bodyFormatToken];
	[self prefsChanged:eventTitleFormatToken];
	[self prefsChanged:eventBodyFormatToken];
}

- (NSTokenStyle)tokenField:(NSTokenField *)tokenField styleForRepresentedObject:(id)representedObject {
	//NSLog(@"style for object: %@", representedObject);
	if ([representedObject isKindOfClass:[NSString class]]) {
		NSString *rps = (NSString *)representedObject;
		if (ISPLACEHOLDER(rps)) {
			return NSRoundedTokenStyle;
		}
	}
	return NSPlainTextTokenStyle;
}

- (NSString *)tokenField:(NSTokenField *)tokenField editingStringForRepresentedObject:(id)representedObject {
	//NSLog(@"editing string for repr object: --'%@'--", representedObject);
	return [representedObject description];
}

- (NSString *)tokenField:(NSTokenField *)tokenField displayStringForRepresentedObject:(id)representedObject {
	NSString *ret = [NSString stringWithFormat:@"%@", representedObject];
	BOOL isMailField = [tokenField tag] < 2100;
	if ([representedObject isKindOfClass:[NSString class]]) {
		NSString *rps = (NSString *)representedObject;
#define ForPlaceholderKeyRetIsString(X, Y)	{\
	if ([rps isEqualToString:MAKEPLACEHOLDER(X)]) {\
		ret = Y;\
	}\
}
		if (isMailField) {			
			// mail
			ForPlaceholderKeyRetIsString(GmailMessageDictAuthorEmailKey, @"Mail author's email");
			ForPlaceholderKeyRetIsString(GmailMessageDictAuthorNameKey, @"Mail author's name");
			ForPlaceholderKeyRetIsString(GmailMessageDictDateIssuedKey, @"Date sent (first mail)");
			ForPlaceholderKeyRetIsString(GmailMessageDictDateModifiedKey, @"Date sent (latest mail)");
			ForPlaceholderKeyRetIsString(GmailMessageDictSummaryKey, @"Message");
			ForPlaceholderKeyRetIsString(GmailMessageDictTitleKey, @"Message subject");
		} else {
			// event
			ForPlaceholderKeyRetIsString(GCalEventDictAuthorEmailKey, @"Event author's email");
			ForPlaceholderKeyRetIsString(GCalEventDictAuthorNameKey, @"Event author's name");
			ForPlaceholderKeyRetIsString(GCalEventDictDateIssuedKey, @"Date created");
			ForPlaceholderKeyRetIsString(GCalEventDictDateModifiedKey, @"Date modified");
			ForPlaceholderKeyRetIsString(GCalEventDictTitleKey, @"Title");
			ForPlaceholderKeyRetIsString(GCalEventDictEventStatusKey, @"Event status");
			ForPlaceholderKeyRetIsString(GCalEventDictWhereKey, @"Event location");
			ForPlaceholderKeyRetIsString(GCalEventDictSummaryKey, @"Event summary");
			ForPlaceholderKeyRetIsString(GCalEventAutoEventTimeKey, @"Event time");
			ForPlaceholderKeyRetIsString(GCalEventAutoWhereSummaryKey, @"Event location+summary");
			ForPlaceholderKeyRetIsString(GCalEventAutoSummaryWhereKey, @"Event summary+location");
		}
	}
	return ret;
}

- (NSArray *)tokenField:(NSTokenField *)tokenField shouldAddObjects:(NSArray *)tokens atIndex:(unsigned)index {
	//NSLog(@"should add objects? %@ at index? %i", tokens, index);	
	
	NSString *t = [tokens componentsJoinedByString:@""];
	[NSTimer scheduledTimerWithTimeInterval:0.2
									  target:self
									selector:@selector(saveTokenFields:)
									userInfo:nil
									 repeats:NO];
	NSArray *retval = [self separateStringIntoTokens:t tokenField:tokenField];
	//NSLog(@"retval: %@", retval);
	return retval;
}
- (void)saveTokenFields:(NSTimer*)theTimer {
	[self prefsChanged:titleFormatToken];
	[self prefsChanged:bodyFormatToken];
	[self prefsChanged:eventTitleFormatToken];
	[self prefsChanged:eventBodyFormatToken];
}

- (BOOL)tokenField:(NSTokenField *)tokenField writeRepresentedObjects:(NSArray *)objects toPasteboard:(NSPasteboard *)pboard {
	//NSLog(@"token field: %d, write represented objects: %@ to pasteboard: %@", [tokenField tag], objects, pboard);
	[pboard setString:[objects componentsJoinedByString:@""] forType:NSStringPboardType];
	NSArray *types = [pboard types];
	NSEnumerator *typeEnumerator = [types objectEnumerator];
	NSString *type;
	while (type = [typeEnumerator nextObject]) {
		//NSLog(@"pboard has type %@, value %@", type, [pboard stringForType:type]);
	} 
	return YES;
}

- (NSArray *)tokenField:(NSTokenField *)tokenField readFromPasteboard:(NSPasteboard *)pboard {
	//NSLog(@"tokenField: %d, read from pasteboard: %@", [tokenField tag], pboard);
	NSArray *types = [pboard types];
	NSEnumerator *typeEnumerator = [types objectEnumerator];
	NSString *type;
	while (type = [typeEnumerator nextObject]) {
		//NSLog(@"pboard has type %@, value %@", type, [pboard stringForType:type]);
	} 
	return [self separateStringIntoTokens:[pboard stringForType:NSStringPboardType] tokenField:tokenField];
}

- (NSArray *)tokenField:(NSTokenField *)tokenField completionsForSubstring:(NSString *)substring indexOfToken:(int)tokenIndex indexOfSelectedItem:(int *)selectedIndex {   
	
	BOOL isMailField = ([tokenField tag] < 2100);
	
	NSEnumerator *phEnumerator = [(isMailField ? GMNGrowlMailPlaceholders : GMNGrowlEventPlaceholders) objectEnumerator];
	NSString *ph;
	NSMutableArray *comps = [NSMutableArray array];
	while (ph = [phEnumerator nextObject]) {
		if ([ph hasPrefix:substring]) {
			[comps addObject:ph];
		}
	}
	return comps;
}

- (id)tokenField:(NSTokenField *)tokenField representedObjectForEditingString:(NSString *)editingString {
	//NSLog(@"repr object for editing string: %@", editingString);
	return editingString;
}

- (NSString *)replace:(NSString *)r with:(NSString *)w inString:(NSString *)str {
	//NSLog(@"replace: --'%@'-- with --'%@'-- in --'%@'--", r, w, str);
	return [[str componentsSeparatedByString:r] componentsJoinedByString:w];
}

- (NSArray *)separateStringIntoTokens:(NSString *)str tokenField:(NSTokenField *)tokenField {
	//NSLog(@"separate string: --'%@'-- into tokens", str);
	BOOL isMailField = ([tokenField tag] < 2100);
	NSEnumerator *phEnumerator = [(isMailField ? GMNGrowlMailPlaceholders : GMNGrowlEventPlaceholders) objectEnumerator];
	NSString *ph;
	NSString *sepString = @"~~~#\t#~~~";
	NSRange r;
	do {
		sepString = [sepString stringByAppendingString:@"1"];
		r = [str rangeOfString:sepString];
	} while (!NSEqualRanges(r,NSMakeRange(NSNotFound,0)));
	while (ph = [phEnumerator nextObject]) {
		str = [self replace:[NSString stringWithFormat:@"%@", ph] 
					   with:[NSString stringWithFormat:@"%@%@%@", sepString, ph, sepString]
				   inString:str];
	} 
	
	return [str componentsSeparatedByString:sepString];
}

CF_RETURNS_RETAINED
- (CFPropertyListRef)preferenceWithKey:(NSString *)preferenceKey {
	CFStringRef cfkey = (CFStringRef)preferenceKey;
	CFPropertyListRef propListPreference = CFPreferencesCopyValue(cfkey, kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	return propListPreference;
}

- (BOOL)boolPreferenceWithKey:(NSString *)preferenceKey fallback:(BOOL)fallback {
	CFPropertyListRef propListPreference = [self preferenceWithKey:preferenceKey];
	if (propListPreference == NULL) {
		return fallback;
	}
	if (CFGetTypeID(propListPreference) != CFBooleanGetTypeID()) { // wrong type?!
		CFRelease(propListPreference);
		return fallback;
	} else {
		CFBooleanRef boo = (CFBooleanRef)propListPreference;
		BOOL wasTrue = (boo == kCFBooleanTrue);
		CFRelease(propListPreference); // not strictly needed, but let's uphold the pattern		
		return wasTrue;
	}
}

- (NSString *)stringPreferenceWithKey:(NSString *)preferenceKey fallback:(NSString *)fallback {
	CFPropertyListRef propListPreference = [self preferenceWithKey:preferenceKey];
	NSString *actualFallback = (fallback ? [fallback copy] : nil);
	NSString *returnString = actualFallback;
	if (propListPreference == NULL) {
		return actualFallback;
	}
	
	if (CFGetTypeID(propListPreference) == CFStringGetTypeID()) {
		CFStringRef cfstr = (CFStringRef)propListPreference;
		NSString *str = [(NSString *)cfstr copy]; // this way, CFRelease can be used uniformly and under GC
		returnString = [str autorelease];
	}
	CFRelease(propListPreference);
	return returnString;
}

- (NSNumber *)numberPreferenceWithKey:(NSString *)preferenceKey fallback:(NSNumber *)fallback {
	CFPropertyListRef propListPreference = [self preferenceWithKey:preferenceKey];
	NSNumber *actualFallback = (fallback ? [fallback copy] : nil);
	NSNumber *returnNumber = actualFallback;
	if (propListPreference == NULL) {
		return actualFallback;
	}
	
	if (CFGetTypeID(propListPreference) == CFNumberGetTypeID()) {
		CFNumberRef cfnum = (CFNumberRef)propListPreference;
		NSNumber *num = [(NSNumber *)cfnum copy]; // this way, CFRelease can be used uniformly and under GC
		returnNumber = [num autorelease];
	}
	CFRelease(propListPreference);
	return returnNumber;
}

- (void) updateFields {

//	[self syncDisableEnable];
	
#define ON_IF_YES(x)	(x ? NSOnState : NSOffState)
#define ON_IF_NO(x)		(x ? NSOffState : NSOnState)
	
	[isMailEnabled setState:ON_IF_YES([self boolPreferenceWithKey:GMNGrowlMailEnabledUDK fallback:YES])];
	[isEventEnabled setState:ON_IF_YES([self boolPreferenceWithKey:GMNGrowlEventEnabledUDK fallback:YES])];
	
	[abIcons setState:ON_IF_NO([self boolPreferenceWithKey:GMNGrowlDontUseABIconsUDK fallback:YES])];
	
	BOOL showOnClick = !([self boolPreferenceWithKey:GMNGrowlDontShowOnClickUDK fallback:YES]);
	[showMess setState:ON_IF_YES(showOnClick)];
	[chosenBrowser setEnabled:showOnClick];
	
	BOOL evtShowOnClick = !([self boolPreferenceWithKey:GMNGrowlEventDontShowOnClickUDK fallback:YES]);
	[showEvent setState:ON_IF_YES(evtShowOnClick)];
	[eventChosenBrowser setEnabled:evtShowOnClick];
	
	
	NSString *messageTitle = [self stringPreferenceWithKey:GMNGrowlNotificationFormatUDK fallback:nil];
	NSString *messageBody = [self stringPreferenceWithKey:GMNGrowlNotificationTextFormatUDK fallback:nil];
	
	[titleFormatToken setObjectValue:[self separateStringIntoTokens:((messageTitle != nil) ? messageTitle : GMNGrowlNotificationFormat) tokenField:titleFormatToken]];
	[bodyFormatToken setObjectValue:[self separateStringIntoTokens:((messageBody != nil) ? messageBody : GMNGrowlNotificationTextFormat) tokenField:bodyFormatToken]];
	
	NSString *eventTitle = [self stringPreferenceWithKey:GMNGrowlEventNotificationFormatUDK fallback:nil];
	NSString *eventBody = [self stringPreferenceWithKey:GMNGrowlEventNotificationTextFormatUDK fallback:nil];
	
	[eventTitleFormatToken setObjectValue:[self separateStringIntoTokens:((eventTitle != nil) ? eventTitle : GMNGrowlEventNotificationFormat) tokenField:eventTitleFormatToken]];
	[eventBodyFormatToken setObjectValue:[self separateStringIntoTokens:((eventBody != nil) ? eventBody : GMNGrowlEventNotificationTextFormat) tokenField:eventBodyFormatToken]];
	
	NSNumber *n = [self numberPreferenceWithKey:GMNGrowlMaxNotificationsCapUDK fallback:[NSNumber numberWithInt:0]];
	int rn;
	int iv = [n intValue];
	if ((iv < 1) || (iv > 20))
		rn = 6;
	else
		rn = iv;
	[maxNot setIntValue:rn];
	[maxNotT takeIntValueFrom:maxNot];
	
	n = [self numberPreferenceWithKey:GMNGrowlEventMaxNotificationsCapUDKUDK fallback:[NSNumber numberWithInt:0]];
	iv = [n intValue];
	if ((iv < 1) || (iv > 20))
		rn = 6;
	else
		rn = iv;
	[eventMaxNot setIntValue:rn];
	[eventMaxNotT takeIntValueFrom:eventMaxNot];
}

- (NSString *)browserToUse {
	NSString *browserident = [self stringPreferenceWithKey:GMNGrowlShowInWhichBrowserUDK fallback:nil];
	return (browserident != nil ? browserident : [self identifierForBundle:[self urlToDefaultBrowser]]);
}

- (NSString *)eventBrowserToUse {
	NSString *browserident = [self stringPreferenceWithKey:GMNGrowlEventShowInWhichBrowserUDK fallback:nil];
	return (browserident != nil ? browserident : [self identifierForBundle:[self urlToDefaultBrowser]]);
}


/*
- (void)toggleDisableEnable {
	CFBooleanRef boo = (CFBooleanRef)CFPreferencesCopyValue((CFStringRef)GMNGrowlDisabledUDK,kCFPreferencesAnyApplication,kCFPreferencesCurrentUser,kCFPreferencesAnyHost);
	BOOL bo = (boo == kCFBooleanTrue);
	bo = !bo;
	CFPreferencesSetValue((CFStringRef)GMNGrowlDisabledUDK,(bo ? kCFBooleanTrue : kCFBooleanFalse),kCFPreferencesAnyApplication,kCFPreferencesCurrentUser,kCFPreferencesAnyHost);
	if (CFPreferencesSynchronize(kCFPreferencesAnyApplication,kCFPreferencesCurrentUser,kCFPreferencesAnyHost))
		GMNLog(@"Preferences synchronized.");
	[self syncDisableEnable];
}

- (void)syncDisableEnable {
	CFBooleanRef boo = (CFBooleanRef)CFPreferencesCopyValue((CFStringRef)GMNGrowlDisabledUDK,kCFPreferencesAnyApplication,kCFPreferencesCurrentUser,kCFPreferencesAnyHost);
	BOOL bo = (boo == kCFBooleanTrue);
	[enableDisableDesc setStringValue:[NSString stringWithFormat:@"Growler for Google Notifier is currently %@", (bo ? @"disabled!" : @"enabled.")]];
	[enableDisable setTitle:(bo ? @"Enable" : @"Disable")];
}*/

- (IBAction)prefsChanged:(id)sender
{
	NSString *key = nil; CFPropertyListRef value; BOOL proceed = NO;
	switch ([sender tag]) {
		case GMNGrowlDontUseABIconsTag:
		case GMNGrowlDontShowOnClickTag:
		case GMNGrowlEventDontShowOnClickTag:
			value = (([(NSButton *)sender state] == NSOffState) ? kCFBooleanTrue : kCFBooleanFalse);
			proceed = YES;
			if ([sender tag] == GMNGrowlDontShowOnClickTag) {
				[chosenBrowser setEnabled:([(NSButton *)sender state] == NSOnState)];
			}
			if ([sender tag] == GMNGrowlEventDontShowOnClickTag) {
				[eventChosenBrowser setEnabled:([(NSButton *)sender state] == NSOnState)];
			}
			break;
		case GMNGrowlEventEnabledTag:
		case GMNGrowlMailEnabledTag:
			value = (([(NSButton *)sender state] == NSOnState) ? kCFBooleanTrue : kCFBooleanFalse);			
//			//NSLog(@"%d changed, value: %@", [sender tag], (value == kCFBooleanTrue) ? @"YES" : @"NO");
			proceed = YES;
			break;
		case GMNGrowlNotificationFormatTag:
		case GMNGrowlNotificationFormatTextTag:
		case GMNGrowlEventNotificationFormatTag:
		case GMNGrowlEventNotificationFormatTextTag:
			value = (CFStringRef)[(NSTextField *)sender stringValue];
			if ([[sender objectValue] isKindOfClass:[NSArray class]])
				value = (CFStringRef)[(NSArray *)[sender objectValue] componentsJoinedByString:@""];
//			//NSLog(@"string value: %@", (NSString *)value);
			proceed = YES;
			break;
			/*
		case GMNGrowlDisabledTag:
			value = (([(NSButton *)sender state] == NSOffState) ? kCFBooleanTrue : kCFBooleanFalse);
			[self toggleDisableEnable];
			break;*/
		case GMNGrowlMaxNotificationsCapTag:
		case GMNGrowlEventMaxNotificationsCapTag:
			value = (CFNumberRef)[NSNumber numberWithInt:[(NSStepper *)sender intValue]];
			[(([sender tag] == GMNGrowlEventMaxNotificationsCapTag) ? eventMaxNotT : maxNotT) takeIntValueFrom:sender];
			proceed = YES;
			break;
	}
	if (proceed) {
			key = (NSString *)[GMNGrowlLookupDict objectForKey:GMNGrowlLookupNumber([sender tag])];
//			//NSLog(@"key: %@ (metakey: %@)", key, GMNGrowlLookupNumber([sender tag]));
			CFPreferencesSetValue((CFStringRef)key,value,kCFPreferencesAnyApplication,kCFPreferencesCurrentUser,kCFPreferencesAnyHost);
			if (CFPreferencesSynchronize(kCFPreferencesAnyApplication,kCFPreferencesCurrentUser,kCFPreferencesAnyHost))
				GMNLog(@"Preferences synchronized.");
	}
	
}

- (IBAction)pickEventBrowser:(id)sender {
	NSString *value = (NSString *)[(NSMenuItem *)sender representedObject];
//	//NSLog(@"pick event browser: %@", value);
	
	NSString *key = (NSString *)[GMNGrowlLookupDict objectForKey:GMNGrowlLookupNumber([eventChosenBrowser tag])];
	CFPreferencesSetValue((CFStringRef)key,(CFStringRef)value,kCFPreferencesAnyApplication,kCFPreferencesCurrentUser,kCFPreferencesAnyHost);
	if (CFPreferencesSynchronize(kCFPreferencesAnyApplication,kCFPreferencesCurrentUser,kCFPreferencesAnyHost))
		GMNLog(@"Browser picked; Preferences synchronized.");
}

- (IBAction)pickBrowser:(id)sender {
	
	NSString *value = (NSString *)[(NSMenuItem *)sender representedObject];
//	//NSLog(@"pick mail browser: %@", value);
	
	NSString *key = (NSString *)[GMNGrowlLookupDict objectForKey:GMNGrowlLookupNumber([chosenBrowser tag])];
	CFPreferencesSetValue((CFStringRef)key,(CFStringRef)value,kCFPreferencesAnyApplication,kCFPreferencesCurrentUser,kCFPreferencesAnyHost);
	if (CFPreferencesSynchronize(kCFPreferencesAnyApplication,kCFPreferencesCurrentUser,kCFPreferencesAnyHost))
		GMNLog(@"Browser picked; Preferences synchronized.");
}

- (void)constructBrowserMenu { 
	
	NSMutableArray *list = [[[self allBrowsers] allObjects] mutableCopy];
	[list sortUsingFunction:&CompareBundleIDAppDisplayNames context:NULL];

	NSMenu *m = [[NSMenu alloc] initWithTitle:@"Mail Browsers"];
	NSMenu *em = [[NSMenu alloc] initWithTitle:@"Event Browsers"];
	NSMenuItem *mi = [[NSMenuItem alloc] initWithTitle:@"Default Browser" action:@selector(pickBrowser:) keyEquivalent:@""];
	NSString *selectedIdentMail = [self browserToUse];
	NSMenuItem *selectedMail = nil;
	NSString *selectedIdentCal = [self eventBrowserToUse];
	NSMenuItem *selectedCal = nil;
	
	NSURL *urlToDef = [self urlToDefaultBrowser];
	
	NSString *ident = [self identifierForBundle:urlToDef];
	NSString *defaultIdent = ident;
	if ((ident != nil) && ([[NSNull null] isNotEqualTo:ident])) {
		mi = [self menuItemForBrowserAtURL:urlToDef];
		[mi setTitle:[NSString stringWithFormat:@"%@ (system browser)", [mi title]]];
	
		if ([selectedIdentMail isEqualToString:ident])
			selectedMail = mi;
		
		if ([selectedIdentCal isEqualToString:ident])
			selectedCal = mi;
	
		[m addItem:mi];
		[m addItem:[NSMenuItem separatorItem]];
		
		mi = [mi copy];
		[mi setAction:@selector(pickEventBrowser:)];
		[em addItem:mi];
		[em addItem:[NSMenuItem separatorItem]];
	}
	
	NSEnumerator *browserEnumerator = [list objectEnumerator];
	while (ident = [browserEnumerator nextObject]) {
		if (([ident isNotEqualTo:defaultIdent]) && (ident != nil) && ([[NSNull null] isNotEqualTo:ident])) {
			mi = [self menuItemForBrowserAtURL:[NSURL fileURLWithPath:[[NSBundle bundleWithIdentifier:ident] bundlePath]]];
			[m addItem:mi];
			if ([selectedIdentMail isEqualToString:ident])
				selectedMail = mi;
			mi = [mi copy];
			[mi setAction:@selector(pickEventBrowser:)];
			[em addItem:mi];
			if ([selectedIdentCal isEqualToString:ident])
				selectedCal = mi;
		}
	} 
	
	[list release];
	
	[chosenBrowser setMenu:[m autorelease]];
	[eventChosenBrowser setMenu:[em autorelease]];
	if (nil == selectedMail)
		[chosenBrowser selectItemAtIndex:0];
	else
		[chosenBrowser selectItemWithTitle:[selectedMail title]];
	
//	//NSLog(@"selected mail browser: %@, selected cal browser: %@", selectedIdentMail, selectedIdentCal);
//	//NSLog(@"selected mail browser: %@, selected cal browser: %@", selectedMail, selectedCal);
	
	if (nil == selectedCal)
		[eventChosenBrowser selectItemAtIndex:0];
	else
		[eventChosenBrowser selectItemWithTitle:[selectedCal title]];
	
}

- (NSURL *)urlToDefaultBrowser {
	NSURL *url;
	LSGetApplicationForURL((CFURLRef)[NSURL URLWithString:@"http://www.google.com/"],kLSRolesViewer,NULL,(CFURLRef *)&url);
	return url;
}

- (NSMenuItem *)menuItemForBrowserAtURL:(NSURL *)url {
	NSMenuItem *mi = [[NSMenuItem alloc] initWithTitle:@"" action:@selector(pickBrowser:) keyEquivalent:@""];
	NSString *ident = [self identifierForBundle:url];
	if (!((ident != nil) && ([[ident stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isNotEqualTo:@""])))
		return nil;
	
	NSString *browserName = [[NSFileManager defaultManager] displayNameAtPath:[url path]];
	NSImage *browserIcon = [[NSWorkspace sharedWorkspace] iconForFile:[url path]];
	[browserIcon setSize:NSMakeSize(16.0,16.0)];
	
	[mi setTitle:browserName];
	[mi setImage:browserIcon];
	[mi setRepresentedObject:ident];
	[mi setTarget:self];
	[mi setEnabled:YES];
	
	return [mi autorelease];
}

- (NSSet *)allBrowsers { 
	NSMutableSet *browsers = [NSMutableSet setWithCapacity:10];
	NSArray *apps;
	apps = [(NSArray *)LSCopyApplicationURLsForURL((CFURLRef)[NSURL URLWithString:@"http://www.google.com/"],kLSRolesViewer) autorelease];
	NSEnumerator *appURLEnumerator = [apps objectEnumerator];
	NSURL *appURL;
	NSString *identifier;
	while (appURL = [appURLEnumerator nextObject]) {
		Boolean canHandleHTTPS;
		if ((LSCanURLAcceptURL((CFURLRef)[NSURL URLWithString:@"https:"], (CFURLRef)appURL, kLSRolesAll, kLSAcceptDefault, &canHandleHTTPS) == noErr) && canHandleHTTPS) {
			if (identifier = [self identifierForBundle:appURL]) {
				if (([[identifier stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isNotEqualTo:@""]) && (identifier != nil)) {
					[browsers addObject:identifier];
				}
			}
				
		}
	} 

	return browsers;
	
}

- (NSString*)identifierForBundle:(NSURL*)inBundleURL {
//	//NSLog(@"G+G: identifier for bundle: %@", (inBundleURL ? inBundleURL : @"nil"));
	if (nil == inBundleURL) return nil;           
	
	NSBundle* tmpBundle = [NSBundle bundleWithPath:[[inBundleURL path] stringByStandardizingPath]];
	if (tmpBundle) {
		NSString* tmpBundleID = [tmpBundle bundleIdentifier];
		if ((tmpBundleID != nil) && ([[tmpBundleID stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isNotEqualTo:@""])) {
			return tmpBundleID;
		}
	}
	return nil;
}

- (void)windowDidResignKey:(NSNotification *)aNotification {
	[self updateFields];
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification {
	[self updateFields];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
	return YES;
}

@end
