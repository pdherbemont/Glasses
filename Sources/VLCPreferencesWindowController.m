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

@implementation VLCPreferencesWindowController

- (void)awakeFromNib
{
    [[SUUpdater sharedUpdater] setDelegate: self];
    [self syncSettings];
}

- (NSString *)windowNibName
{
    return @"PreferencesWindow";
}

- (void)dealloc
{
    if (_currentView) {
        [_currentView release];
    }
    [super dealloc];
}

- (void)syncSettings
{
    SUUpdater *updater = [SUUpdater sharedUpdater];
    NSDate *lastUpdateCheckDate = [[SUUpdater sharedUpdater] lastUpdateCheckDate];
    NSString *string;
    if (lastUpdateCheckDate) {
        NSString *date = [lastUpdateCheckDate descriptionWithLocale:[NSLocale currentLocale]];
        string = [NSString stringWithFormat: @"Last check on: %@", date];
    } else
        string = @"No check was performed yet.";
    [_lastCheckForUpdateText setStringValue:string];
    [_checkForUpdatesCheckBox setIntValue:[updater automaticallyChecksForUpdates]];
    if (!_currentView) {
        /* this is only performed on the first display of this window */
        [[self window] setTitle:@"General"];
        [self setView: _generalSettingsView];
        [[[[[self window] toolbar] items] objectAtIndex: 0] setImage: [NSImage imageNamed: NSImageNamePreferencesGeneral]];
        [[[[[self window] toolbar] items] objectAtIndex: 1] setImage: [NSImage imageNamed: NSImageNameSlideshowTemplate]];
        [[[self window] toolbar] setSelectedItemIdentifier: @"general"];
    }
    if ([[NSUserDefaults standardUserDefaults] stringForKey: @"SelectedSnapshotFolder"])
        [_snapshotPathSelector setURL:[NSURL fileURLWithPath:[[[NSUserDefaults standardUserDefaults] stringForKey:@"SelectedSnapshotFolder"] stringByExpandingTildeInPath]]];
    else
        [_snapshotPathSelector setURL: [NSURL fileURLWithPath: [@"~/Desktop" stringByExpandingTildeInPath]]];
}

- (void)updater:(SUUpdater *)updater didFinishLoadingAppcast:(SUAppcast *)appcast
{
    if ([[self window] isVisible])
        [self syncSettings];
}

- (IBAction)showWindow: (id)sender
{
    [self syncSettings];
    [[self window] center];
    [[self window] makeKeyAndOrderFront: nil];
}

- (IBAction)buttonAction: (id)sender
{
    /* FIXME: this is ugly! However, using KVC with Sparkle will result in a crash on app launch */
    [[SUUpdater sharedUpdater] setAutomaticallyChecksForUpdates: [_checkForUpdatesCheckBox intValue]];
    /* saving URLs with KVC is impossible within IB, so let's do it this way... */
    [[NSUserDefaults standardUserDefaults] setObject: [[_snapshotPathSelector URL] path] forKey: @"SelectedSnapshotFolder"];
}

- (IBAction)toolbarAction: (id)sender
{
    if( [sender tag] == 0 ) {
        [[self window] setTitle:@"General"];
        [self setView: _generalSettingsView];
    } else if( [sender tag] == 1 ) {
        [[self window] setTitle:@"Playback"];
        [self setView: _playbackSettingsView];
    } else
        NSLog( @"invalid view requested by toolbar" );

}

- (void)setView: (id)newView
{
    NSRect windowRect, viewRect, oldViewRect;
    windowRect = [[self window] frame];
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

    [[self window] displayIfNeeded];
    [[self window] setFrame: windowRect display:YES animate: YES];

    [newView setFrame: NSMakeRect( 0, 0, viewRect.size.width, viewRect.size.height )];
    [newView setNeedsDisplay: YES];
    [newView setAutoresizesSubviews: YES];
    [[[self window] contentView] addSubview: newView];

    /* keep our current view for future reference */
    [_currentView release];
    _currentView = newView;
    [_currentView retain];
}

@end
