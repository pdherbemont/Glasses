/*****************************************************************************
 * VLCPreferences.m: Preferences dialogue
 *****************************************************************************
 * Copyright (C) 2009 the VideoLAN team
 * $Id: $
 *
 * Authors: Felix Paul Kühne <fkuehne at videolan dot org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/

#import <Sparkle/Sparkle.h>
#import "VLCPreferencesWindowController.h"
#import "VLCDocumentController.h"

@implementation VLCPreferencesWindowController

- (NSString *)windowNibName
{
    return @"PreferencesWindow";
}

- (void)dealloc
{
    VLCAssert(!_currentView, @"This should have been released");
    [super dealloc];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    NSWindow *window = [self window];

    // we want to re-open with the same view we were closed with, so just revert to default on first display
    if (!_currentView) {
        [window setTitle:@"General"];
        [self setView:_generalSettingsView];
        [[window toolbar] setSelectedItemIdentifier:@"general"];
    }

#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    if ([_checkDateFormatter respondsToSelector:@selector(setDoesRelativeDateFormatting:)])
        [_checkDateFormatter setDoesRelativeDateFormatting:YES];
#endif
    [window center];
}

- (SUUpdater *)updater
{
    return [SUUpdater sharedUpdater];
}

- (IBAction)lastFMAction: (id)sender
{
    NSDictionary * userData = [NSDictionary dictionaryWithObjectsAndKeys:
                               [[NSUserDefaults standardUserDefaults] stringForKey:kLastFMEnabled], @"enabled",
                               [[NSUserDefaults standardUserDefaults] stringForKey:klastFMUsername], @"username",
                               [[NSUserDefaults standardUserDefaults] stringForKey:klastFMPassword], @"password", nil];

   [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"VLCLastFMSettingChanged"
                                                                  object:@"VLCLastFMSupport"
                                                                userInfo:userData];
}

- (IBAction)toolbarAction:(id)sender
{
    VLCAssert([sender isKindOfClass:[NSToolbarItem class]], @"Only receive from NSToolbarItem");
    NSToolbarItem *item = sender;
    NSString *identifier = [item itemIdentifier];
    NSWindow *window = [self window];
    if ([identifier isEqualToString:@"general"]) {
        [window setTitle:@"General"];
        [self setView:_generalSettingsView];
    } else if ([identifier isEqualToString:@"advanced"]) {
        [window setTitle:@"Advanced"];
        [self setView:_advancedSettingsView];
    } else if ([identifier isEqualToString:@"playback"]) {
        [window setTitle:@"Playback"];
        [self setView:_playbackSettingsView];
    } else if ([identifier isEqualToString:@"folderScanning"]) {
        [window setTitle:@"Folder Scanning"];
        [self setView:_folderScanningSettingsView];
    } else
        VLCAssertNotReached( @"invalid view requested by toolbar" );
}

- (void)setView:(id)newView
{
    NSRect windowRect, viewRect, oldViewRect;
    NSWindow *window = [self window];

    windowRect = [window frame];
    viewRect = [newView frame];

    if (_currentView != nil) {
        /* restore our window's height, if we've shown another view previously */
        oldViewRect = [_currentView frame];
        windowRect.size.height = windowRect.size.height - oldViewRect.size.height;
        windowRect.origin.y = (windowRect.origin.y + oldViewRect.size.height) - viewRect.size.height;

        /* remove our previous view */
        [_currentView removeFromSuperviewWithoutNeedingDisplay];
    }

    windowRect.size.height = viewRect.size.height + 78; // + toolbar height...

    [window displayIfNeeded];
    [window setFrame:windowRect display:YES animate:YES];

    [newView setFrame:NSMakeRect( 0, 0, viewRect.size.width, viewRect.size.height )];
    [newView setNeedsDisplay:YES];
    [newView setAutoresizesSubviews:YES];
    [[window contentView] addSubview:newView];
    _currentView = newView;
}

- (IBAction)addScannedFolder:(id)sender
{
    NSOpenPanel *openPanel = [[NSOpenPanel alloc] init];

    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanChooseFiles:NO];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSArray *array = [defaults arrayForKey:kScannedFolders];
            [defaults setObject:[array arrayByAddingObjectsFromArray:[openPanel filenames]] forKey:kScannedFolders];
        }
        [openPanel autorelease];
    }];
}
@end
