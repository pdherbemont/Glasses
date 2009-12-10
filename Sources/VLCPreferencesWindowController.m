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
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults stringForKey:@"SelectedSnapshotFolder"])
        [defaults setObject:[@"~/Desktop" stringByExpandingTildeInPath] forKey:@"SelectedSnapshotFolder"];
}

- (NSString *)windowNibName
{
    return @"PreferencesWindow";
}

- (void)dealloc
{
    NSAssert(!_currentView, @"This should have been released");
    [super dealloc];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    [self setView:_generalSettingsView];
    NSWindow *window = [self window];
    NSArray *items = [[window toolbar] items];

    // FIXME - seems to be a bug, it doesn't work from the preferences
    [[items objectAtIndex: 0] setImage: [NSImage imageNamed: NSImageNamePreferencesGeneral]];
    [[items objectAtIndex: 1] setImage: [NSImage imageNamed: NSImageNameSlideshowTemplate]];

    [window center];
}

- (SUUpdater *)updater
{
    return [SUUpdater sharedUpdater];
}

- (IBAction)toolbarAction: (id)sender
{
    NSInteger tag = [sender tag];
    if (tag == 0) {
        [[self window] setTitle:@"General"];
        [self setView: _generalSettingsView];
    } else if (tag == 1) {
        [[self window] setTitle:@"Playback"];
        [self setView: _playbackSettingsView];
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
    [window setFrame: windowRect display:YES animate: YES];

    [newView setFrame: NSMakeRect( 0, 0, viewRect.size.width, viewRect.size.height )];
    [newView setNeedsDisplay: YES];
    [newView setAutoresizesSubviews: YES];
    [[window contentView] addSubview: newView];
    _currentView = newView;
}

@end
