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

- (NSString *)windowNibName
{
    return @"PreferencesWindow";
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
}

- (IBAction)showPreferences: (id)sender
{
    [self syncSettings];
    [[self window] makeKeyAndOrderFront: nil];
}

- (IBAction)buttonAction: (id)sender
{
    /* FIXME: this is ugly! However, using KVC with Sparkle will result in a crash on app launch */
    [[SUUpdater sharedUpdater] setAutomaticallyChecksForUpdates: [_checkForUpdatesCheckBox intValue]];
}

@end
