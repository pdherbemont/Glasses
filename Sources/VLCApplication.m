/*****************************************************************************
 * VLCApplication.h:NSApplication subclass
 *****************************************************************************
 * Copyright (C) 2009 the VideoLAN team
 * $Id:$
 *
 * Authors:Felix Paul Kühne <fkuehne at videolan dot org>
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

#import "VLCApplication.h"
#import "VLCMediaDocument.h"
#import <VLCKit/VLCMediaPlayer.h>
#import <IOKit/hidsystem/ev_keymap.h>         /* for the media key support */

/*****************************************************************************
 * exclusively used to implement media key support on Al Apple keyboards
 *   b_justJumped is required as the keyboard send its events faster than
 *    the user can actually jump through his media
 *****************************************************************************/

@implementation VLCApplication

- (void)awakeFromNib
{
    /* register our default values... */
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:@"YES", @"ControlWithMediaKeys", @"YES", @"ControlWithMediaKeysInBackground", nil]];
    
    [self coreChangedMediaKeySupportSetting:nil];

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(coreChangedMediaKeySupportSetting:) name:@"NSUserDefaultsDidChangeNotification" object:nil];
    [center addObserver:self selector:@selector(applicationDidBecomeActiveOrInactive:) name:@"NSApplicationDidBecomeActiveNotification" object:nil];
    [center addObserver:self selector:@selector(applicationDidBecomeActiveOrInactive:) name:@"NSApplicationWillResignActiveNotification" object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)applicationDidBecomeActiveOrInactive:(NSNotification *)notification
{
    BOOL hasResignedActive = [[notification name] isEqualToString:@"NSApplicationWillResignActiveNotification"];
    if ((hasResignedActive && !_isActiveInBackground ) || !_hasMediaKeySupport)
        _isActive = NO;
    else
        _isActive = YES;
}

- (void)coreChangedMediaKeySupportSetting:(NSNotification *)notification
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    _isActive = _hasMediaKeySupport = [defaults boolForKey:@"ControlWithMediaKeys"];
    _isActiveInBackground = [defaults boolForKey:@"ControlWithMediaKeysInBackground"];
}


- (void)sendEvent:(NSEvent*)event
{
    if (_isActive) {
        if ([event type] == NSSystemDefined && [event subtype] == 8) {
            int keyCode =  ([event data1] & 0xFFFF0000) >> 16;
            int keyFlags = [event data1] & 0x0000FFFF;
            int keyState = ((keyFlags & 0xFF00) >> 8) == 0xA;
            int keyRepeat = keyFlags & 0x1;

            VLCMediaPlayer *mediaPlayer = [[[[NSDocumentController sharedDocumentController] currentDocument] mediaListPlayer] mediaPlayer];
        
            if (keyCode == NX_KEYTYPE_PLAY && keyState == 0 && [mediaPlayer canPause])
                [mediaPlayer pause];
 
            if (keyCode == NX_KEYTYPE_FAST && !_hasJustJumped) {
                if (keyRepeat == 1) {
                    [mediaPlayer shortJumpForward];
                    _hasJustJumped = YES;
                    [self performSelector:@selector(resetJump) withObject:nil afterDelay:0.25];
                }
            }
            
            if (keyCode == NX_KEYTYPE_REWIND && !_hasJustJumped) {
                if (keyRepeat == 1) {
                    [mediaPlayer shortJumpBackward];
                    _hasJustJumped = YES;
                    [self performSelector:@selector(resetJump) withObject:nil afterDelay:0.25];
                }
            }
        }
    }
    [super sendEvent:event];
}

- (void)resetJump
{
    _hasJustJumped = NO;
}

@end

