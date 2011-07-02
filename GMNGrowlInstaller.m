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
//  GMNGrowlInstaller.m
//  GMNGrowl
//
//  Created by Jesper on 2005-09-19.
//

#import "GMNGrowlInstaller.h"

#import "UtilityController.h"
#import "PrefsController.h"

#define GMNGrowlInstallerGMNBundleName			@"GoogleGrowl.plugin"

#define GMNGrowlInstallerAppSupportPath			[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"]
#define GMNGrowlInstallerGMNPluginPath			[GMNGrowlInstallerAppSupportPath stringByAppendingPathComponent:@"Google Notifier"]
#define GMNGrowlInstallerDestPath				[GMNGrowlInstallerGMNPluginPath stringByAppendingPathComponent:GMNGrowlInstallerGMNBundleName]

#define GMNGrowlInstallerConflictingGMNBundleName	@"GmailGrowl.plugin"
#define GMNGrowlInstallerConflictingBundlePath		[[GMNGrowlInstallerAppSupportPath stringByAppendingPathComponent:@"Gmail Notifier"] stringByAppendingPathComponent:GMNGrowlInstallerConflictingGMNBundleName]
#define GMNGrowlInstallerConflictingBisBundlePath		[[GMNGrowlInstallerAppSupportPath stringByAppendingPathComponent:@"Google Notifier"] stringByAppendingPathComponent:GMNGrowlInstallerConflictingGMNBundleName]
#define GMNGrowlInstallerConflictingBundleTrashPath	[[NSHomeDirectory() stringByAppendingPathComponent:@".Trash"] stringByAppendingPathComponent:GMNGrowlInstallerConflictingGMNBundleName]

#define GMNGrowlInstallerDoQuitGMNAlertText		@"Do you want to quit Google Notifier and continue?"
#define GMNGrowlInstallerDoQuitGMNAlertInfo		@"Growler for Google Notifier will not be available until Google Notifier has been restarted. Do you want to quit Google Notifier now and continue with the installation? Google Notifier will be restarted automatically after the installation is complete."
#define GMNGrowlInstallerDoQuitGMNAlertYes		@"Quit Google Notifier and Continue"
#define GMNGrowlInstallerDoQuitGMNAlertNo		@"Cancel"
#define GMNGrowlInstallerDoQuitGMNAlertCtx		@"GMNGrowlInstallerDoQuitGMNAlert"
#define GMNGrowlInstallerDoQuitGMNAppleScript	@"tell app \"Google Notifier\" to quit"

#define GMNGrowlInstallerTrashConflictingGMNAlertText	@"Do you want to remove old versions of Growler for Google Notifier?"
#define GMNGrowlInstallerTrashConflictingGMNAlertInfo	@"A version of Gmail+Growl has been found and will interfere with normal use of Growler for Google Notifier. The file will be placed in the Trash for easy recovery, if needed."
#define GMNGrowlInstallerTrashConflictingGMNAlertYes		@"Remove Gmail+Growl and Continue"
#define GMNGrowlInstallerTrashConflictingGMNAlertNo		@"Cancel"
#define GMNGrowlInstallerTrashConflictingGMNAlertCtx		@"GMNGrowlInstallerTrashConflictingGMNAlert"

#define GMNGrowlInstallerTrashConflictingErrorAlertText		@"An error occured when trying to remove an old version of Growler for Google Notifier."
#define GMNGrowlInstallerTrashConflictingErrorAlertInfo		@"Please try to remove the file manually, and then attempt installation again. Press Reveal in Finder to open a Finder window with the file selected. The file is located at %@."
#define GMNGrowlInstallerTrashConflictingErrorAlertOK		@"OK"
#define GMNGrowlInstallerTrashConflictingErrorAlertReveal	@"Reveal in Finder"

#define GMNGrowlInstallerShouldQuitGMNAlertText		@"Please quit Google Notifier now!"
#define GMNGrowlInstallerShouldQuitGMNAlertInfo		@"Growler for Google Notifier will not be available until Google Notifier has been restarted. Google Notifier will be restarted automatically after the installation is complete. Please quit Google Notifier manually, and then click OK."
#define GMNGrowlInstallerShouldQuitGMNAlertOK		@"OK"
#define GMNGrowlInstallerShouldQuitGMNAlertCtx		@"GMNGrowlInstallerShouldQuitGMNAlert"

#define GMNGrowlInstallerASErrorAlertText		@"An error occured when trying to quit Google Notifier. Please quit Google Notifier manually, and then click Continue."
#define GMNGrowlInstallerASErrorAlertOK			@"Continue"

@interface NSWorkspace (GMNGrowlInstallerAdditions)
+ (BOOL) isGMNRunning;
@end

@implementation NSWorkspace (GMNGrowlInstallerAdditions)
+ (BOOL) isGMNRunning {
	
	Class runningAppClass = NSClassFromString(@"NSRunningApplication");
	if (runningAppClass != Nil) {
		NSArray *runningApps = [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.google.GmailNotifier"];
		// this is not a type; they really still have "GmailNotifier" as their bundle ID
		
		if ([runningApps count] > 1) return YES; // Too many! Probably a Google Notifier developer machine. Back out.
		if ([runningApps count] == 0) return NO;
		NSRunningApplication *runningApp = [runningApps lastObject];
		
		BOOL terminated = (runningApp == nil ? YES : [runningApp isTerminated]);
		
		return !terminated;
	}
	
	/** Heavily borrowed from <http://borkware.com/quickies/one?topic=NSTask>. */
	
	NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath: @"/bin/bash"];
	
	[task setArguments:[NSArray arrayWithObjects: @"-c",
			@"ps cx | grep \"Google Notifier\"", nil]]; 
	/** Huh?
	*** ps cx -- 'c' means show executable name only (hides the grep's 
	***          own process or any other process launched with 'Google
	***          Notifier' in the arguments)
	***       -- 'x' means to list processes without a controlling
	***          terminal - like Google Notifier.
	*** grep  -- from the list `ps` returns, look for a row with
	***          'Google Notifier' in it
	*/
	
	NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
	
    NSFileHandle *file;
    file = [pipe fileHandleForReading];
	
    [task launch];
	[task waitUntilExit];
	
    NSData *data = [file readDataToEndOfFile];
	
    NSString *string = [[NSString alloc] initWithData: data
											 encoding: NSUTF8StringEncoding];
	
	[task release];
	
	return !([[string autorelease] isEqualToString:@""]);
	
}

@end

@implementation GMNGrowlInstaller

- (void)awakeFromNib {
	hasInstalled = NO;
	NSSize minSize = [[self window] minSize];
	[[self window] setMaxSize:NSMakeSize(minSize.width,[[self window] maxSize].height)];

	gmnWasOpen = NO;
	
	[installButton setTitle:[NSString stringWithFormat:@"Install %@", [[NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"GoogleGrowl" ofType:@"plugin" inDirectory:@"GoogleGrowl"]] objectForInfoDictionaryKey:@"CFBundleVersion"]]];
	
}

- (IBAction)install:(id)sender
{
	if (!hasInstalled) {
		
		if (!hasGottenThroughConflictingRemoval) {
			
			if ([[NSFileManager defaultManager] fileExistsAtPath:GMNGrowlInstallerConflictingBundlePath] || [[NSFileManager defaultManager] fileExistsAtPath:GMNGrowlInstallerConflictingBisBundlePath]) {
				NSAlert *doRemoveConflicting = [NSAlert alertWithMessageText:GMNGrowlInstallerTrashConflictingGMNAlertText
													  defaultButton:GMNGrowlInstallerTrashConflictingGMNAlertYes
													alternateButton:GMNGrowlInstallerTrashConflictingGMNAlertNo
														otherButton:nil
										  informativeTextWithFormat:GMNGrowlInstallerTrashConflictingGMNAlertInfo];
				[doRemoveConflicting beginSheetModalForWindow:[self window]
									   modalDelegate:self
									  didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) 
										 contextInfo:GMNGrowlInstallerTrashConflictingGMNAlertCtx];		
			} else {
				hasGottenThroughConflictingRemoval = YES;
				[self install:self];
			}
		} else {
		
			if ([NSWorkspace isGMNRunning]) {
				gmnWasOpen = YES;
		
				/** Quitting Google Notifier by Apple Events is busted. This should be uncommented when it works. */
#if 0
				NSAlert *doContinue = [NSAlert alertWithMessageText:GMNGrowlInstallerDoQuitGMNAlertText
													  defaultButton:GMNGrowlInstallerDoQuitGMNAlertYes
													alternateButton:GMNGrowlInstallerDoQuitGMNAlertNo
														otherButton:nil
										  informativeTextWithFormat:GMNGrowlInstallerDoQuitGMNAlertInfo];
				[doContinue beginSheetModalForWindow:[self window]
									   modalDelegate:self
									  didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) 
										 contextInfo:GMNGrowlInstallerDoQuitGMNAlertCtx];
#else
				NSAlert *doContinue = [NSAlert alertWithMessageText:GMNGrowlInstallerShouldQuitGMNAlertText
													  defaultButton:GMNGrowlInstallerShouldQuitGMNAlertOK
													alternateButton:nil
														otherButton:nil
										  informativeTextWithFormat:GMNGrowlInstallerShouldQuitGMNAlertInfo];
				[doContinue beginSheetModalForWindow:[self window]
									   modalDelegate:self
									  didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) 
										 contextInfo:GMNGrowlInstallerShouldQuitGMNAlertCtx];		
#endif
			} else {
				[self doInstall];
			}		
			
		}

	} else {
		if (gmnWasOpen) {
			[[NSWorkspace sharedWorkspace] launchApplication:@"Google Notifier"];	
		}	
		[[utilityController prefs]  showWindow:self];
		[[self window] orderOut:self];
	}
	
}

- (void)doInstall {
	[installButton setHidden:YES];
	[moreButton setHidden:YES];
	[installingProgress setHidden:NO];
	
	[title setStringValue:@"Installing..."];
	[notice setStringValue:@"Growler for Google Notifier is being installed..."];

	[installingProgress setUsesThreadedAnimation:YES];
	[installingProgress startAnimation:self];
	
	[[self window] display];
	
	BOOL isDir; BOOL exists;
	exists = [[NSFileManager defaultManager] fileExistsAtPath:GMNGrowlInstallerGMNPluginPath isDirectory:&isDir];
	if (!(exists) || !(isDir)) {
		NSLog(@"-WTF: Exists: %@, isDir: %@.", (exists ? @"YES" : @"NO"),  (isDir ? @"YES" : @"NO"));
		if (![[NSFileManager defaultManager] createDirectoryAtPath:GMNGrowlInstallerGMNPluginPath attributes:nil]) {
			[self showNotice:@"Growler for Google Notifier can't be installed because the Google Notifier plugin folder can't be created." title:@"Installation failed"];
			NSLog(@"-ERR: Installer can't create folder at %@.", GMNGrowlInstallerGMNPluginPath);
			return;
		}
	}
	if ([[NSFileManager defaultManager] fileExistsAtPath:GMNGrowlInstallerDestPath]) {
		NSLog(@"-WTF: Exists... remove it.");
		if(![[NSFileManager defaultManager] removeFileAtPath:GMNGrowlInstallerDestPath handler:nil]) {
			[self showNotice:@"Growler for Google Notifier can't be installed because the older version can't be removed." title:@"Installation failed"];
			NSLog(@"-ERR: Installer can't remove older version at %@.", GMNGrowlInstallerDestPath);
			return;	
		}
	}
	
	if (![[NSFileManager defaultManager] copyPath:[[NSBundle mainBundle] pathForResource:@"GoogleGrowl" ofType:@"plugin" inDirectory:@"GoogleGrowl"] toPath:GMNGrowlInstallerDestPath handler:nil]) {
		[self showNotice:[NSString stringWithFormat:@"Growler for Google Notifier can't be installed because the plugin can't be copied to %@.", [GMNGrowlInstallerGMNPluginPath stringByAppendingPathComponent:@"GoogleGrowl.plugin"]] title:@"Installation failed"];
		NSLog(@"-ERR: Installer can't copy plugin to %@.", [GMNGrowlInstallerGMNPluginPath stringByAppendingPathComponent:@"GoogleGrowl.plugin"]);
		return;
	}
	[self showNotice:@"Growler for Google Notifier was successfully installed." title:@"Installation completed"];
}

- (BOOL)removeConflictingBundle:(NSString *)pathToConflictingBundle {
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *bundleTrashBase = [GMNGrowlInstallerConflictingBundleTrashPath stringByDeletingPathExtension];
	NSString *bundleTrashExt = [GMNGrowlInstallerConflictingBundleTrashPath pathExtension];
	NSString *bundleTrashCandidate = GMNGrowlInstallerConflictingBundleTrashPath;
	int i = 2;
	while ([fm fileExistsAtPath:bundleTrashCandidate]) {
		bundleTrashCandidate = [NSString stringWithFormat:@"%@ %i.%@", bundleTrashBase, i, bundleTrashExt];
		i++;
	}
	if (![fm fileExistsAtPath:pathToConflictingBundle]) return YES;
	if (![fm movePath:pathToConflictingBundle toPath:bundleTrashCandidate handler:nil]) {
		return NO;
	} else {
		return YES;
	}
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode  contextInfo:(void  *)contextInfo {
	if ([(NSString *)contextInfo isEqualToString:GMNGrowlInstallerDoQuitGMNAlertCtx]) {
		[[alert window] orderOut:self];
		if (returnCode == NSAlertDefaultReturn) {
			NSAppleScript *aps = [[NSAppleScript alloc] initWithSource:GMNGrowlInstallerDoQuitGMNAppleScript];
			NSDictionary *error = nil;
			[aps executeAndReturnError:&error];
			[aps autorelease];
			if (nil != error)
				[[NSAlert alertWithMessageText:GMNGrowlInstallerASErrorAlertText
								 defaultButton:GMNGrowlInstallerASErrorAlertOK
							   alternateButton:nil
								   otherButton:nil
					 informativeTextWithFormat:@"AppleScript error: %@ (%@)",
					[error objectForKey:NSAppleScriptErrorMessage],
					[error objectForKey:NSAppleScriptErrorNumber]] runModal];
			[self doInstall];
		}
	} else if ([(NSString *)contextInfo isEqualToString:GMNGrowlInstallerShouldQuitGMNAlertCtx]) {
		[[alert window] orderOut:self];
		[self doInstall];
	} else if ([(NSString *)contextInfo isEqualToString:GMNGrowlInstallerTrashConflictingGMNAlertCtx]) {
		[[alert window] orderOut:self];
		if (returnCode == NSAlertDefaultReturn) {
			BOOL succeeded = NO;
			succeeded = [self removeConflictingBundle:GMNGrowlInstallerConflictingBundlePath];
			if (succeeded) {
				succeeded = [self removeConflictingBundle:GMNGrowlInstallerConflictingBisBundlePath];
			}
			if (!succeeded) {
				NSAlert *erroralert = [NSAlert alertWithMessageText:GMNGrowlInstallerTrashConflictingErrorAlertText
												 defaultButton:GMNGrowlInstallerTrashConflictingErrorAlertOK
											   alternateButton:nil
												   otherButton:GMNGrowlInstallerTrashConflictingErrorAlertReveal
									 informativeTextWithFormat:GMNGrowlInstallerTrashConflictingErrorAlertInfo,
					GMNGrowlInstallerConflictingBundlePath];
				int result = [erroralert runModal];
				if (result == NSAlertThirdButtonReturn) {
					[[NSWorkspace sharedWorkspace] selectFile:GMNGrowlInstallerConflictingBundlePath inFileViewerRootedAtPath:[GMNGrowlInstallerConflictingBundlePath stringByDeletingLastPathComponent]];
				}
			} else {
				hasGottenThroughConflictingRemoval = YES;
				[self install:self];
			}
		}
	}
}

- (void)showNotice:(NSString *)str title:(NSString *)ti {
	[installingProgress stopAnimation:self];
	[installingProgress setHidden:YES];
	
	NSAlert *al = [NSAlert alertWithMessageText:ti defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@", str];
	[al beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:NULL contextInfo:NULL];
	
	[installButton setHidden:NO];
	
		hasInstalled = YES;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
	return YES;
}

@end
