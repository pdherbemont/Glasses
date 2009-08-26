/*****************************************************************************
 * Copyright (C) 2009 the VideoLAN team
 *
 * Authors: Pierre d'Herbemont
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

#import "VLCExtendedVideoView.h"
#import "NSScreen_Additions.h"

@implementation VLCExtendedVideoView
@synthesize mediaPlayer=_mediaPlayer;

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (BOOL)fullscreen
{
    return _isFullscreen;
}

- (BOOL)mouseDownCanMoveWindow;
{
    return YES;
}

- (BOOL)isOpaque
{
    return YES;
}

- (void)setFullscreen:(BOOL)fullscreen
{
    if (_isFullscreen == fullscreen)
        return;

    _isFullscreen = fullscreen;
    
	if (_isFullscreen) {
        NSAssert(!_fullscreenController, @"There should not be any controller");
        _fullscreenController = [[VLCFullscreenController alloc] init];
		NSScreen *screen = [[self window] screen];
		if ([screen isMainScreen])
			[NSMenu setMenuBarVisible:NO];
		
		[_fullscreenController enterFullscreen:screen];
	} else {
        [_fullscreenController leaveFullscreen];
        [_fullscreenController release];
        _fullscreenController = nil;
		[NSMenu setMenuBarVisible:YES];
        [self exitFullScreenModeWithOptions:nil];
	}
}

- (void)cancelOperation:(id)sender
{
    [self setFullscreen:![self fullscreen]];
}

- (void)mouseDown:(NSEvent *)event
{
	if ([event clickCount] == 2)
		[self setFullscreen:![self fullscreen]];
}
@end
