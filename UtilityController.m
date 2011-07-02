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
//  UtilityController.m
//  GMNGrowl
//
//  Created by Jesper on 2006-02-16.
//

#import "UtilityController.h"

#import "GMNGrowlInstaller.h"
#import "PrefsController.h"

#define GMNUtilityAppSupportPath		[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"]
#define GMNUtilityGMNPluginPath			[GMNUtilityAppSupportPath stringByAppendingPathComponent:@"Google Notifier"]
#define GMNUtilityDestPath				[GMNUtilityGMNPluginPath stringByAppendingPathComponent:@"GoogleGrowl.plugin"]

@implementation UtilityController

- (void)awakeFromNib {
	BOOL isDir;
	
	prefs = [[PrefsController sharedPreferencesWindowController] retain];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:GMNUtilityDestPath isDirectory:&isDir] && isDir) {
	
		NSBundle *b = [NSBundle bundleWithPath:GMNUtilityDestPath];
		NSString *n = (NSString *)[b objectForInfoDictionaryKey:@"CFBundleVersion"];
		
		NSBundle *b2 = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"GoogleGrowl" ofType:@"plugin" inDirectory:@"GoogleGrowl"]];
		NSString *n2 = (NSString *)[b2 objectForInfoDictionaryKey:@"CFBundleVersion"];
		
		NSComparisonResult cr = [n2 compare:n options:NSNumericSearch];
		
		if (cr == NSOrderedDescending) {
			[[installer window] makeKeyAndOrderFront:self];
			//[[prefs window] orderOut:self];
			return;
		}
		
	} else {
			[[installer window] makeKeyAndOrderFront:self];
			//[[prefs window] orderOut:self];
			return;
	}
	[self showPrefs:nil];
	//[[installer window] orderOut:self];
}

- (PrefsController *)prefs {
	return prefs;
}

- (GMNGrowlInstaller *)installer {
	return installer;
}

- (IBAction)showPrefs:(id)sender {
	[prefs showWindow:sender];
}

@end
