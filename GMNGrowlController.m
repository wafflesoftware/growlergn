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
//  GMNGrowlController.m
//  GMNGrowl
//
//  Created by Jesper on 2005-09-02.
//

#import <Growl-WithInstaller/Growl.h>
//#import <Growl/Growl.h>

#import "GGPluginProtocol.h"
#import "GMNGrowlController.h"

/* Almost all defines have been moved to the pch. */

@interface NSDate (HasTimeAdditions)
- (BOOL)hasTime;
@end

@implementation NSDate (HasTimeAdditions)
- (BOOL)hasTime { return YES; }
@end

@interface GMNPlaceholderTool : NSObject
+ (NSString *)replaceString:(NSString *)replace withString:(NSString *)with inString:(NSString *)subject;
+ (NSString *)replacePlaceholdersInString:(NSString *)str withPlaceholderDict:(NSDictionary *)dict;
@end

#pragma mark Placeholder replacement (for format strings)
@implementation GMNPlaceholderTool
+ (NSString *)replacePlaceholdersInString:(NSString *)str withPlaceholderDict:(NSDictionary *)dict {
	
	NSEnumerator *phEnumerator = [dict keyEnumerator];
	NSString *ph;
	id object;
	while (ph = [phEnumerator nextObject]) {
		object = [dict objectForKey:ph];
		if ([object isKindOfClass:[NSDate class]]) {
			object = [[(NSDate *)object dateWithCalendarFormat:[[NSUserDefaults standardUserDefaults] objectForKey:@"NSShortTimeDateFormatString"] timeZone:nil] descriptionWithLocale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]];
			/** Construct an NSCalendarDate, because they automatically show nicer dates. */
		}
		str = [GMNPlaceholderTool replaceString:MAKEPLACEHOLDER(ph)
					   withString:[object description]
					     inString:str];
	} 
	
	return str;
	
}

+ (NSString *)replaceString:(NSString *)replace withString:(NSString *)with inString:(NSString *)subject {
	return [[subject componentsSeparatedByString:replace] componentsJoinedByString:with];
}
@end

@implementation GMNGrowlController

#pragma mark -
#pragma mark Initialization, plugin registration, Growl registration

- (id)init {
	self = [super init];
	GMNLog(@"Growler for Google Notifier: initing Growler for Google Notifier 3.0.");
	NSBundle *myBundle = [NSBundle bundleForClass:[GMNGrowlController class]];
	NSString *growlPath = [[myBundle privateFrameworksPath]
        stringByAppendingPathComponent:@"Growl-WithInstaller.framework"];
//        stringByAppendingPathComponent:@"Growl.framework"];
	GMNLog(@"Growler for Google Notifier: path to growl: %@", growlPath);
	NSBundle *growlBundle = [NSBundle bundleWithPath:growlPath];
	GMNLog(@"Growler for Google Notifier: growlBundle: %@", growlBundle);
	if (growlBundle && [growlBundle load]) {
        // Register ourselves as a Growl delegate
        [GrowlApplicationBridge setGrowlDelegate:self];
	} else {
		/**TODO** Better error handling. */
        GMNLog(@"-ERR: Could not load Growl framework.");
	}
	
	openedURLs = [[NSSet set] mutableCopy];
	
	urlThrottler = [NSTimer scheduledTimerWithTimeInterval:50.0f target:self selector:@selector(emptyThrottler:) userInfo:nil repeats:YES];
	return self;
}

- (void)emptyThrottler:(NSTimer*)theTimer {
//	GMNLog(@"Emptying throttler");
	[openedURLs removeAllObjects];
}

static BOOL runningFromUtility = NO;

+ (void)setIsRunningFromUtility {
	runningFromUtility = YES;
	GMNLog(@"Growler for Google Notifier: running from inside the utility");
}

+ (void)pluginLoaded {
#if CompileJustNotifyOnceSupport
	if (!runningFromUtility) {
		[[NSUserDefaults standardUserDefaults] setObject:[NSArray array] forKey:GMNGrowlJustNotifyOnceListUDK];
	}
#endif
	GMNLog(@"Growler for Google Notifier: Plugin loaded; Growler for Google Notifier 3.0.");
}

+ (void)pluginWillUnload {
	GMNLog(@"Growler for Google Notifier: Plugin about to unload; Growler for Google Notifier 3.0.");
}

- (void)dealloc {

	[openedURLs release];
	
	[super dealloc];
	
}

- (NSString *) applicationNameForGrowl {
	return @"Growler for Google Notifier";
}

- (void)growlIsReady {
	GMNLog(@"Growler for Google Notifier: Growl is ready for Google Notifier!");
}

- (NSDictionary *) registrationDictionaryForGrowl {
	return [NSDictionary dictionaryWithObjectsAndKeys:
		[NSArray arrayWithObjects:GMNGrowlNewMailNotification, GMNGrowlNewEventNotification, nil], GROWL_NOTIFICATIONS_ALL,
		[NSArray arrayWithObjects:GMNGrowlNewMailNotification, GMNGrowlNewEventNotification, nil], GROWL_NOTIFICATIONS_DEFAULT, 
		nil];
}

#pragma mark -
#pragma mark Installation or Update box for Growl

- (NSAttributedString *)growlInstallationInformation {
	GMNLog(@"Growler for Google Notifier: asked for installation info");
	return [[[NSAttributedString alloc] initWithString:GrowlInstallInfo attributes:[NSDictionary dictionaryWithObject:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]] forKey:NSFontAttributeName]] autorelease];
}

- (NSString *)growlInstallationWindowTitle {
	return GrowlInstallTitle;
}
- (NSAttributedString *)growlUpdateInformation {
	return [[[NSAttributedString alloc] initWithString:GrowlUpdateInfo attributes:[NSDictionary dictionaryWithObject:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]] forKey:NSFontAttributeName]] autorelease];	
}
- (NSString *)growlUpdateWindowTitle {
	return GrowlUpdateTitle;
}

#pragma mark -
#pragma mark New messages handler

- (void)newMessagesReceived:(NSArray *)messages
                  fullCount:(int)fullCount {
	
	GMNLog(@"Growler for Google Notifier! New messages received, full count: %i, messages: %@", fullCount, messages);
	
	NSEnumerator *messageEnumerator = [messages objectEnumerator];
	NSDictionary *messageDict;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	[defaults synchronize]; /** Always, ALWAYS get the latest settings. */
	
	/* disabling is deprecated
	if ([[NSUserDefaults standardUserDefaults] boolForKey:GMNGrowlDisabledUDK]) {
		GMNLog(@"Growler for Google Notifier! Disabled, not showing %i unread message notifications", fullCount);
		return;
	}*/

#if CompileJustNotifyOnceSupport
	
	BOOL checkForMessagesToIgnore = NO;
	BOOL ignoreMessages = NO;
	NSMutableArray *messagesToIgnore = nil;
	if ([defaults boolForKey:GMNGrowlJustNotifyOnceUDK]) {
		checkForMessagesToIgnore = YES;
		ignoreMessages = YES;
		if (nil == (messagesToIgnore = (NSMutableArray *)[[defaults arrayForKey:GMNGrowlJustNotifyOnceListUDK] mutableCopy])) {
			checkForMessagesToIgnore = NO;
			messagesToIgnore = (NSMutableArray *)[[NSArray array] mutableCopy];
		}
		[messagesToIgnore autorelease];
	}
	
#endif
	
	BOOL useABicon = !([[NSUserDefaults standardUserDefaults] boolForKey:GMNGrowlDontUseABIconsUDK]);
	
	GMNLog(@"Use Address Book icon? %@", (useABicon ? @"YES" : @"NO"));
	
	NSString *mailNotificationTitle = [[NSUserDefaults standardUserDefaults] stringForKey:GMNGrowlNotificationFormatUDK];
	if (!mailNotificationTitle || [mailNotificationTitle isEqualToString:@""])
		mailNotificationTitle = GMNGrowlNotificationFormat;
		
	NSString *mailNotificationText = [[NSUserDefaults standardUserDefaults] stringForKey:GMNGrowlNotificationTextFormatUDK];
	if (!mailNotificationText || [mailNotificationText isEqualToString:@""])
		mailNotificationText = GMNGrowlNotificationTextFormat;
	
	NSString *calNotificationTitle = [[NSUserDefaults standardUserDefaults] stringForKey:GMNGrowlEventNotificationFormatUDK];
	if (!calNotificationTitle || [calNotificationTitle isEqualToString:@""])
		calNotificationTitle = GMNGrowlEventNotificationFormat;
	
	NSString *calNotificationText = [[NSUserDefaults standardUserDefaults] stringForKey:GMNGrowlEventNotificationTextFormatUDK];
	if (!calNotificationText || [calNotificationText isEqualToString:@""])
		calNotificationText = GMNGrowlEventNotificationTextFormat;
	
	id maxNemail = [[NSUserDefaults standardUserDefaults] objectForKey:GMNGrowlMaxNotificationsCapUDK];
	id maxNevent = [[NSUserDefaults standardUserDefaults] objectForKey:GMNGrowlEventMaxNotificationsCapUDKUDK];
	int notificationsCapEmail = GMNGrowlMaxNotificationsCap;
	int notificationsCapEvent = GMNGrowlEventMaxNotificationsCapUDK;
	if (maxNemail)
		notificationsCapEmail = [(NSNumber *)maxNemail intValue];
	if (notificationsCapEmail > 20 || notificationsCapEmail < 1)
		notificationsCapEmail = GMNGrowlMaxNotificationsCap;
	
	if (maxNevent)
		notificationsCapEvent = [(NSNumber *)maxNevent intValue];
	if (notificationsCapEvent > 20 || notificationsCapEvent < 1)
		notificationsCapEvent = GMNGrowlEventMaxNotificationsCapUDK;
	
	BOOL processMail = YES;
	BOOL processEvent = YES;

	id showMail = [[NSUserDefaults standardUserDefaults] objectForKey:GMNGrowlMailEnabledUDK];
	NSLog(@"showMail? %@", showMail);
	if (showMail) {
		processMail = [(NSNumber *)showMail boolValue];
		NSLog(@"showMail is set in prefs;  boolValue is %d", [(NSNumber *)showMail boolValue]);
	}
	else
		processMail = GMNGrowlMailEnabled;
	
	id showEvent = [[NSUserDefaults standardUserDefaults] objectForKey:GMNGrowlEventEnabledUDK];
	NSLog(@"showEvent? %@", showEvent);
	if (showEvent) {
		processEvent = [(NSNumber *)showEvent boolValue];
		NSLog(@"showEvent is set in prefs;  boolValue is %d", [(NSNumber *)showEvent boolValue]);
	}
	else
		processEvent = GMNGrowlEventEnabled;
	
	if (runningFromUtility) {
		NSLog(@"running from utility.");
		processMail = YES;
		processEvent = YES;
	}
	
	int i = 1;
	int emaili = 0;
	int cali = 0;
	NSData *iconData = nil; 
	NSString *pathToGN = [[NSWorkspace sharedWorkspace] fullPathForApplication:@"Google Notifier"];
	NSImage *icon = nil;
	if (pathToGN)
		icon = [[NSWorkspace sharedWorkspace] iconForFile:pathToGN];
	if (icon)
		iconData = [icon TIFFRepresentation];
	GMNLog(@"Growler for Google Notifier! Path to Google Notifier: %@ (icon: %@, icon data length: %u)", pathToGN, icon, (unsigned long)(iconData ? [iconData length] : 0));
	defIcon = [iconData copy];
	while (messageDict = [messageEnumerator nextObject]) {
		NSString *linkURL = [[self urlForMessageDict:messageDict] absoluteString];
		if ([messageDict objectForKey:@"startTime"]) {
			if (!processEvent) continue;
			// CALENDAR EVENTS
			
			NSDictionary *eventDict = [self normalizeEventDict:messageDict];
			GMNLog(@"Growler for Google Notifier! Normalized event dictionary: %@", eventDict);
			
#if CompileJustNotifyOnceSupport
			if (checkForMessagesToIgnore)
				if ([messagesToIgnore containsObject:[eventDict objectForKey:GCalEventDictEventUUIDKey]])
					continue;
			if (ignoreMessages)
				[messagesToIgnore addObject:[eventDict objectForKey:GCalEventDictEventUUIDKey]];
#endif
			
			iconData = defIcon;
			
			GMNLog(@"Growler for Google Notifier! Sending event notification: title: %@, description: %@, notification name: %@, iconData: %u bytes, click context (link): %@",
				   [GMNPlaceholderTool replacePlaceholdersInString:calNotificationTitle withPlaceholderDict:eventDict],
				   [GMNPlaceholderTool replacePlaceholdersInString:calNotificationText withPlaceholderDict:eventDict],
				   GMNGrowlNewEventNotification,
				   (unsigned long)(iconData ? [iconData length] : 0),
				   linkURL);
			
			[GrowlApplicationBridge
		notifyWithTitle:[GMNPlaceholderTool replacePlaceholdersInString:calNotificationTitle withPlaceholderDict:eventDict]
			description:[GMNPlaceholderTool replacePlaceholdersInString:calNotificationText withPlaceholderDict:eventDict]
	   notificationName:GMNGrowlNewEventNotification
			   iconData:iconData
			   priority:0
			   isSticky:NO
		   clickContext:[NSArray arrayWithObjects:[NSNumber numberWithBool:NO], linkURL, nil]]; 
			
			
			cali++;
			if (cali == notificationsCapEvent) {
				GMNLog(@"Growler for Google Notifier! We've reached the calendar event notification cap of %i.", notificationsCapEvent);
				processEvent = NO;
			}
		} else {
			if (!processMail) continue;
			// EMAIL MESSAGES
			
			messageDict = [self normalizeMessageDict:messageDict];
			GMNLog(@"Growler for Google Notifier! Normalized message dictionary: %@", messageDict);
			
#if CompileJustNotifyOnceSupport
			if (checkForMessagesToIgnore)
				if ([messagesToIgnore containsObject:[messageDict objectForKey:GmailMessageDictMailUUIDKey]])
					continue;
			if (ignoreMessages)
				[messagesToIgnore addObject:[messageDict objectForKey:GmailMessageDictMailUUIDKey]];
#endif
			
			GMNLog(@"Growler for Google Notifier! Pre-Address Book-icon: %@", [iconData className]);
			
			if (useABicon)
				iconData = [self iconDataBasedOnSender:[messageDict objectForKey:GmailMessageDictAuthorEmailKey]];
			
			GMNLog(@"Growler for Google Notifier! Post-Address Book-icon: %@", [iconData className]);
			
			GMNLog(@"Growler for Google Notifier! Sending email notification: title: %@, description: %@, notification name: %@, iconData: %u bytes, click context (link): %@",
				   [GMNPlaceholderTool replacePlaceholdersInString:mailNotificationTitle withPlaceholderDict:messageDict],
				   [GMNPlaceholderTool replacePlaceholdersInString:mailNotificationText withPlaceholderDict:messageDict],
				   GMNGrowlNewMailNotification,
				   (unsigned long)(iconData ? [iconData length] : 0),
				   linkURL);
			
			[GrowlApplicationBridge
		notifyWithTitle:[GMNPlaceholderTool replacePlaceholdersInString:mailNotificationTitle withPlaceholderDict:messageDict]
			description:[GMNPlaceholderTool replacePlaceholdersInString:mailNotificationText withPlaceholderDict:messageDict]
	   notificationName:GMNGrowlNewMailNotification
			   iconData:iconData
			   priority:0
			   isSticky:NO
		   clickContext:[NSArray arrayWithObjects:[NSNumber numberWithBool:YES], linkURL, nil]]; 
			
			emaili++;
			if (emaili == notificationsCapEmail) {
				GMNLog(@"Growler for Google Notifier! We've reached the email notification cap of %i.", notificationsCapEmail);
				processMail = NO;
			}
		}

		i++;
	} 
[defIcon release];
#if CompileJustNotifyOnceSupport
	[defaults setObject:messagesToIgnore forKey:GMNGrowlJustNotifyOnceListUDK];
#endif
	[defaults synchronize];
	NSLog(@"new messages received: %@", messages);
}

- (NSDictionary *)normalizeMessageDict:(NSDictionary *)di {
	NSMutableDictionary *d = (NSMutableDictionary *)[[di mutableCopy] autorelease];
	
	NSString *authorName = [d objectForKey:GmailMessageDictAuthorNameKey];
	if (!authorName || [authorName isEqualToString:@""])
		[d setObject:GMNGrowlMissingAuthorName forKey:GmailMessageDictAuthorNameKey];
	
	NSString *subject = [d objectForKey:GmailMessageDictTitleKey];
	if (!subject || [subject isEqualToString:@""])
		[d setObject:GMNGrowlMissingTitle forKey:GmailMessageDictTitleKey];
	
	NSString *summary = [d objectForKey:GmailMessageDictSummaryKey];
	if (!summary || [summary isEqualToString:@""])
		[d setObject:GMNGrowlMissingSummary forKey:GmailMessageDictSummaryKey];
	
	return d;
}

- (NSDictionary *)normalizeEventDict:(NSDictionary *)di {
	NSMutableDictionary *d = (NSMutableDictionary *)[[di mutableCopy] autorelease];
	
	NSString *authorName = [d objectForKey:GCalEventDictAuthorNameKey];
	if (!authorName || [authorName isEqualToString:@""])
		[d setObject:GMNGrowlMissingAuthorName forKey:GCalEventDictAuthorNameKey];
	
	NSString *subject = [d objectForKey:GCalEventDictTitleKey];
	if (!subject || [subject isEqualToString:@""])
		[d setObject:GMNGrowlMissingTitle forKey:GCalEventDictTitleKey];
	
	NSString *summary = [d objectForKey:GCalEventDictSummaryKey];
	if (!summary || [summary isEqualToString:@""])
		[d setObject:GMNGrowlMissingSummary forKey:GCalEventDictSummaryKey];
	
	if ([d objectForKey:GCalEventDictStartTimeKey] && [d objectForKey:GCalEventDictStopTimeKey]) {
		NSDateFormatter *dtf = [[NSDateFormatter alloc] init];
		[dtf setFormatterBehavior:NSDateFormatterBehavior10_4];
		[dtf setDateStyle:NSDateFormatterMediumStyle];
		[dtf setTimeStyle:NSDateFormatterMediumStyle];
		NSString *startTimeS = nil; NSString *stopTimeS = nil; NSString *eventTime = nil;
		CalendarDateRFC3339 *startTime = [d objectForKey:GCalEventDictStartTimeKey];
		CalendarDateRFC3339 *stopTime = [d objectForKey:GCalEventDictStopTimeKey];
		if ([startTime hasTime]) { // not all-day event
			if ([[stopTime descriptionWithCalendarFormat:@"%Y-%m-%d" timeZone:nil locale:nil] isEqualToString:[startTime descriptionWithCalendarFormat:@"%Y-%m-%d" timeZone:nil locale:nil]]) { // same day
				startTimeS = [dtf stringFromDate:startTime];
				[dtf setDateStyle:NSDateFormatterNoStyle];
				stopTimeS = [dtf stringFromDate:stopTime];
			} else {
				startTimeS = [dtf stringFromDate:startTime];
				stopTimeS = [dtf stringFromDate:stopTime];
			}
			eventTime = [NSString stringWithFormat:@"%@ - %@", startTimeS, stopTimeS];
		} else {
			[dtf setTimeStyle:NSDateFormatterNoStyle];
			startTimeS = [dtf stringFromDate:startTime];
			eventTime = [NSString stringWithFormat:@"%@ all-day", startTimeS];
		}
		[d setObject:eventTime forKey:GCalEventAutoEventTimeKey];
		[dtf release];
	}
	
	if ([d objectForKey:GCalEventDictWhereKey]) {
		if ([d objectForKey:GCalEventDictSummaryKey]) {
			[d setObject:[NSString stringWithFormat:@"%@\n%@", [d objectForKey:GCalEventDictWhereKey], [d objectForKey:GCalEventDictSummaryKey]]
				  forKey:GCalEventAutoWhereSummaryKey];
			[d setObject:[NSString stringWithFormat:@"%@\n%@", [d objectForKey:GCalEventDictSummaryKey], [d objectForKey:GCalEventDictWhereKey]]
				  forKey:GCalEventAutoSummaryWhereKey];
		} else {
			[d setObject:[d objectForKey:GCalEventDictWhereKey] forKey:GCalEventAutoWhereSummaryKey];
			[d setObject:[d objectForKey:GCalEventDictWhereKey] forKey:GCalEventAutoSummaryWhereKey];
		}
	} else if ([d objectForKey:GCalEventDictSummaryKey]) {
		[d setObject:[d objectForKey:GCalEventDictSummaryKey] forKey:GCalEventAutoWhereSummaryKey];
		[d setObject:[d objectForKey:GCalEventDictSummaryKey] forKey:GCalEventAutoSummaryWhereKey];
	} else {
		[d setObject:@"" forKey:GCalEventAutoWhereSummaryKey];
		[d setObject:@"" forKey:GCalEventAutoSummaryWhereKey];	
	}
	
	return d;
}

- (void) growlNotificationWasClicked:(id)clickContext {
	
	UInt32 mod = GetCurrentKeyModifiers();
	BOOL inv = ((mod & shiftKey) != 0);
	
	GMNLog(@"clicked. (context: %@)", clickContext);

	NSArray *ctx = (NSArray *)clickContext;
	NSString *u = [ctx lastObject];
	BOOL isMail = [(NSNumber *)[ctx objectAtIndex:0] boolValue];
	
	BOOL dontShow = [[NSUserDefaults standardUserDefaults] boolForKey:(isMail ? GMNGrowlDontShowOnClickUDK : GMNGrowlEventDontShowOnClickUDK)];
	
	GMNLog(@"don't show? %@, inv? %@", (dontShow ? @"Y" : @"N"), (inv ? @"Y" : @"N"));
	
	if ((dontShow) || (!dontShow && inv))
		return;
	
	NSString *browserBundle = [[NSUserDefaults standardUserDefaults] stringForKey:(isMail ? GMNGrowlShowInWhichBrowserUDK : GMNGrowlEventShowInWhichBrowserUDK)];
	if (!browserBundle || [browserBundle isEqualToString:@""])
		browserBundle = [self defaultBrowser];
	
//	NSURL *url = [self urlForMessageDict:dict];
	NSURL *url = [NSURL URLWithString:u];
	
	if ([openedURLs containsObject:url]) {
		GMNLog(@"Growler for Google Notifier: Throttled opening of: %@", url);
		return;
	}
	
	NSLog(@"open url: %@ in browser: %@", url, browserBundle);
	
	[openedURLs addObject:url];

	if ([browserBundle isEqualToString:[self defaultBrowser]])
		[[NSWorkspace sharedWorkspace] openURL:url];
	else
		[[NSWorkspace sharedWorkspace] openURLs:[NSArray arrayWithObject:url]
						withAppBundleIdentifier:browserBundle
										options:NSWorkspaceLaunchDefault 
				 additionalEventParamDescriptor:nil
							  launchIdentifiers:NULL];

}

#define GMNGrowlStringIsNilOrEmpty(x)	(x == nil || [@"" isEqualToString:[x stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]])

#define	GMNGrowlComputesURLOnItsOwn		0

- (NSURL *)urlForMessageDict:(NSDictionary *)di {
	
	/** Fork in the road!
	*** Gmail Notifier never produced a usable value for the link entry.
	*** With Gmail Notifier, we have to compute our own.
	*** Google Notifier does provide its own.
	*** The define to change here is right above the method header. */
#if GMNGrowlComputesURLOnItsOwn
	/** How to construct a URL to open a message. Start by getting the UUID in Hex. */
	
	NSString *ident = [di objectForKey:GmailMessageDictMailUUIDKey];
	/** ident now contains "tag:gmail.google.com,2004:number". */
	
	/** Find the range of the second colon. (The first is a part of 'tag:'.) */
	NSRange cor = [ident rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@":"]
										 options:NSBackwardsSearch];
	ident = [ident substringFromIndex:cor.location];
	/** ident now contains ":number". */
	
	NSScanner *sc = [NSScanner scannerWithString:ident];
	[sc scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:NULL];
	long long hexid;
	[sc scanLongLong:&hexid];
	
	ident = [NSString stringWithFormat:@"%qX", hexid];
	/** ident now contains our number in hex. */
	
	/** The second part is getting the account. 
		*** The only way we can do this is by fishing it straight out of Gmail Notifier's preferences.
		*** Heinous, I know. */
	
	NSString *acc = (NSString *)((CFStringRef)CFPreferencesCopyAppValue((CFStringRef)@"Username",(CFStringRef)@"com.google.GmailNotifier"));
	[acc autorelease];
	
	/** Only one value by splitting the string with @ means that there's no @.
	*** Probable cause - just the username entered and not the email. Do the
	*** right thing (like Gmail and Gmail Notifier) and slap on @gmail.com at the end. */
	
	if ([[acc componentsSeparatedByString:@"@"] count] == 1)
		acc = [acc stringByAppendingString:@"@gmail.com"];
	
	/** URL escape the @ in the username, if needed. */
	acc = [acc stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	
	/** Now, assemble the URL and return it. */
	return [NSURL URLWithString:[NSString stringWithFormat:@"https://mail.google.com/mail?account_id=%@&message_id=%@&view=gds_conv", acc, ident]];
#else
	NSString *linkEntry = [di objectForKey:@"link"];
	NSString *linkWithSecurityPolicyEntry = [di objectForKey:@"linkWithSecurityPolicy"];
	
	return [NSURL URLWithString:(GMNGrowlStringIsNilOrEmpty(linkWithSecurityPolicyEntry) ? linkEntry : linkWithSecurityPolicyEntry)];
#endif
	
}

- (NSData *)iconDataBasedOnSender:(NSString *)email {
	GMNLog(@"Looking for Address Book icon for %@.", email);
	ABAddressBook *AB = [ABAddressBook sharedAddressBook];
	ABSearchElement *wanted = [ABPerson searchElementForProperty:kABEmailProperty
									 label:nil
									   key:nil
									 value:email
								comparison:kABEqualCaseInsensitive];
	NSArray *people = [AB recordsMatchingSearchElement:wanted];
	if (!people || [people count]<1) {
		GMNLog(@"No icon found - no corresponding people.");
		return defIcon;
	}
//	GMNLog(@"found people: %@", people);
	NSEnumerator *peopleEnumerator = [people objectEnumerator];
	ABRecord *rec;
	while (rec = [peopleEnumerator nextObject]) {
//		GMNLog(@"guy: %@", [rec class]);
		if (![rec respondsToSelector:@selector(imageData)])
			continue;
		ABPerson *guy = (ABPerson *)rec;
//		ABMultiValue *mv = [guy valueForProperty:kABEmailProperty];
		NSData *d = [guy imageData]; 
		if (d != nil) {
			GMNLog(@"Found icon!, %@", d);
			return d;
		}
	} 
	GMNLog(@"No icon found - no icon set for any corresponding people.");
	return defIcon;
}

- (NSString *)defaultBrowser {
	NSURL *url;
	LSGetApplicationForURL((CFURLRef)[NSURL URLWithString:@"http://www.google.com/"],kLSRolesViewer,NULL,(CFURLRef *)&url);

	NSBundle* tmpBundle = [NSBundle bundleWithPath:[[url path] stringByStandardizingPath]];
	if (tmpBundle) {
		NSString* tmpBundleID = [tmpBundle bundleIdentifier];
		if (tmpBundleID && ([tmpBundleID length] > 0)) {
			return tmpBundleID;
		}
	}
	return nil;
	
}

@end
