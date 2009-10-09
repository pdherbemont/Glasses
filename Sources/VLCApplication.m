/*****************************************************************************
 * VLCApplication.h: NSApplication subclass
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
    [[NSUserDefaults standardUserDefaults] registerDefaults: [NSDictionary dictionaryWithObjectsAndKeys: @"YES", @"ControlWithMediaKeys", @"YES", @"ControlWithMediaKeysInBackground", nil]];
    
    [self coreChangedMediaKeySupportSetting: nil];

    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(coreChangedMediaKeySupportSetting:) name: @"NSUserDefaultsDidChangeNotification" object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(appGotActiveOrInactive:) name: @"NSApplicationDidBecomeActiveNotification" object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(appGotActiveOrInactive:) name: @"NSApplicationWillResignActiveNotification" object: nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [super dealloc];
}

- (void)appGotActiveOrInactive: (NSNotification *)o_notification
{
    if(( [[o_notification name] isEqualToString: @"NSApplicationWillResignActiveNotification"] && !b_activeInBackground ) || !b_mediaKeySupport)
        b_active = NO;
    else
        b_active = YES;
}

- (void)coreChangedMediaKeySupportSetting: (NSNotification *)o_notification
{
    b_active = b_mediaKeySupport = [[[NSUserDefaults standardUserDefaults] objectForKey: @"ControlWithMediaKeys"] intValue];
    b_activeInBackground = [[[NSUserDefaults standardUserDefaults] objectForKey: @"ControlWithMediaKeysInBackground"] intValue];
}


- (void)sendEvent: (NSEvent*)event
{
    if( b_active )
	{
        if( [event type] == NSSystemDefined && [event subtype] == 8 )
        {
            int keyCode = (([event data1] & 0xFFFF0000) >> 16);
            int keyFlags = ([event data1] & 0x0000FFFF);
            int keyState = (((keyFlags & 0xFF00) >> 8)) == 0xA;
            int keyRepeat = (keyFlags & 0x1);
            
            if( keyCode == NX_KEYTYPE_PLAY && keyState == 0 && [[[[[NSDocumentController sharedDocumentController] currentDocument] mediaListPlayer] mediaPlayer] canPause] )
                [[[[[NSDocumentController sharedDocumentController] currentDocument] mediaListPlayer] mediaPlayer] pause];
 
            if( keyCode == NX_KEYTYPE_FAST && !b_justJumped )
            {
                if( keyRepeat == 1 )
                {
                    [[[[[NSDocumentController sharedDocumentController] currentDocument] mediaListPlayer] mediaPlayer] shortJumpForward];
                    b_justJumped = YES;
                    [self performSelector:@selector(resetJump)
                               withObject: NULL
                               afterDelay:0.25];
                }
            }
            
            if( keyCode == NX_KEYTYPE_REWIND && !b_justJumped )
            {
                if( keyRepeat == 1 )
                {
                    [[[[[NSDocumentController sharedDocumentController] currentDocument] mediaListPlayer] mediaPlayer] shortJumpBackward];
                    b_justJumped = YES;
                    [self performSelector:@selector(resetJump)
                               withObject: NULL
                               afterDelay:0.25];
                }
            }
        }
    }
    [super sendEvent: event];
}

- (void)resetJump
{
    b_justJumped = NO;
}

@end

