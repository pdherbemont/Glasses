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
#import "VLCPreferences.h"

@implementation VLCPreferences

static VLCPreferences *_o_sharedInstance = nil;

+ (VLCPreferences *)sharedInstance
{
    return _o_sharedInstance ? _o_sharedInstance : [[self alloc] init];
}

- (id)init
{
    if (_o_sharedInstance) {
        [self dealloc];
    } else {
        _o_sharedInstance = [super init];
        if( !b_nib_loaded )
            b_nib_loaded = [NSBundle loadNibNamed:@"Preferences" owner:self];
    }
    
    return _o_sharedInstance;
}

- (void)syncSettings {
    if( [[SUUpdater sharedUpdater] lastUpdateCheckDate] != NULL )
        [o_lastCheckForUpdate_txt setStringValue: [NSString stringWithFormat: @"Last check on: %@", [[[SUUpdater sharedUpdater] lastUpdateCheckDate] descriptionWithLocale: [[NSUserDefaults standardUserDefaults] dictionaryRepresentation]]]];
    else
        [o_lastCheckForUpdate_txt setStringValue: @"No check was performed yet."];
    [o_checkForUpdates_ckb setIntValue: [[SUUpdater sharedUpdater] automaticallyChecksForUpdates]];
}

- (IBAction)showPreferences: (id)sender {
    [self syncSettings];

    [o_prefs_win makeKeyAndOrderFront: nil];
}

- (IBAction)buttonAction: (id)sender {
    /* FIXME: this is ugly! However, using KVC with Sparkle will result in a crash on app launch */
    [[SUUpdater sharedUpdater] setAutomaticallyChecksForUpdates: [o_checkForUpdates_ckb intValue]];
}

@end
