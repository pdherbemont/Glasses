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

/* See VLCStyledVideoWindowView.h for background */

#import <Cocoa/Cocoa.h>
#import "VLCFullscreenController.h"

@class VLCExtendedVideoView;
@class VLCStyledVideoWindowView;
@interface VLCStyledVideoWindowController : NSWindowController {
    IBOutlet VLCExtendedVideoView *_videoView;
    IBOutlet NSView *_containerForVideoView;
    IBOutlet VLCStyledVideoWindowView *_styledWindowView;
    IBOutlet NSButton *_accessoryButton;
    IBOutlet NSView *_accessoryView;
    VLCFullscreenController *_fullscreenController;
}
- (void)toggleFullscreen:(id)sender;
- (void)toggleFloatingWindow:(id)sender;
- (void)enterFullscreen;

- (void)setStyleWantsCocoaTitleBar:(BOOL)titleBar;

@property (readonly, retain) VLCExtendedVideoView *videoView;

@property (readonly, retain) VLCStyledVideoWindowView *styledWindowView;

@end
