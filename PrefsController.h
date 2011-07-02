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
//  PrefsController.h
//  GMNGrowl
//
//  Created by Jesper on 2005-09-28.
//

#import <Cocoa/Cocoa.h>

@class GGPluginProtocol;

@interface PrefsController : NSWindowController
{
	// gmail
    IBOutlet NSButton *abIcons;
    IBOutlet NSButton *showMess;
	
    IBOutlet NSStepper *maxNot;
    IBOutlet NSTextField *maxNotT;
	
    IBOutlet NSPopUpButton *chosenBrowser;
	
	IBOutlet NSTokenField *titleFormatToken;
	IBOutlet NSTokenField *bodyFormatToken;
	IBOutlet NSTokenField *templatesToken;
	IBOutlet NSTextField *templatesResizeTo;

	// gcal
    IBOutlet NSButton *showEvent;
	
    IBOutlet NSStepper *eventMaxNot;
    IBOutlet NSTextField *eventMaxNotT;
	
    IBOutlet NSPopUpButton *eventChosenBrowser;
	
	IBOutlet NSTokenField *eventTitleFormatToken;
	IBOutlet NSTokenField *eventBodyFormatToken;
	IBOutlet NSTokenField *eventTemplatesToken;
	IBOutlet NSTextField *eventTemplatesResizeTo;
	
    IBOutlet NSButton *isMailEnabled;
    IBOutlet NSButton *isEventEnabled;
	
	GGPluginProtocol *ggForTesting;
	
	IBOutlet NSView *prefsView;
	IBOutlet NSView *aboutView;
	
}

+ (PrefsController *)sharedPreferencesWindowController;

- (IBAction)launchGrowlPrefPane:(id)sender;

- (IBAction)previewEventNotification:(id)sender;
- (IBAction)previewMailNotification:(id)sender;

- (IBAction)websiteClicked:(id)sender;
- (IBAction)relatedWebsiteClicked:(id)sender;

- (IBAction)prefsChanged:(id)sender;
- (IBAction)pickEventBrowser:(id)sender;
- (IBAction)pickBrowser:(id)sender;
- (void) updateFields;
/*
- (void)toggleDisableEnable;
- (void)syncDisableEnable;*/

- (NSArray *)separateStringIntoTokens:(NSString *)str tokenField:(NSTokenField *)tokenField;

- (NSString*)identifierForBundle:(NSURL*)inBundleURL;
- (NSMenuItem *)menuItemForBrowserAtURL:(NSURL *)url;
- (NSURL *)urlToDefaultBrowser;
- (NSSet *)allBrowsers;
- (void)constructBrowserMenu;
//	static int CompareBundleIDAppDisplayNames(id a, id b, void *context);
@end
