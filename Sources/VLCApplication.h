/*****************************************************************************
 * VLCApplication.h: NSApplication subclass
 *****************************************************************************
 * Copyright (C) 2009-2010 the VideoLAN team
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

#import <Cocoa/Cocoa.h>
#import <VLCKit/VLCKit.h>
#import "AppleRemote.h"
#import "VLCCrashReporter.h"

@interface VLCApplication : NSApplication {
    BOOL _hasJustJumped;
    BOOL _hasMediaKeySupport;
    BOOL _isActiveInBackground;
    BOOL _isActive;
    BOOL _controlWithRemote;

    VLCCrashReporter *_crashReporter;
    AppleRemote * _remote;
    BOOL _remoteButtonIsHold; /* true as long as the user holds the left,right,plus or minus on the remote control */
}

- (void)applicationDidBecomeActiveOrInactive:(NSNotification *)notification;
- (void)sendEvent:(NSEvent *)event;
- (void)resetJump;

- (IBAction)reportBug:(id)sender;
- (IBAction)showVideoLANWebsite:(id)sender;

- (IBAction)runCommandLineVLC:(id)sender;
@end
