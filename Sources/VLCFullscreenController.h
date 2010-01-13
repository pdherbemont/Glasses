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

#import <Cocoa/Cocoa.h>

/* This is the code responsible for moving a view to fullscreen.
 *
 * A window controller will typically create a fullscreen
 * controller set the view to go fullscreen.
 *
 * The window will also set the HUD window to use.
 */

@protocol VLCFullscreenHUD;
@protocol VLCFullscreenDelegate;

extern NSInteger VLCFullscreenWindowLevel(void);
extern NSInteger VLCFullscreenHUDWindowLevel(void);

@interface VLCFullscreenController : NSObject {
    NSView *_view;
    NSWindow *_originalViewWindow;

    id <VLCFullscreenHUD> _hud;

    id <VLCFullscreenDelegate> _delegate;

    NSView *_placeholderView;

    NSWindow *_fullscreenWindow;
    NSViewAnimation *_animation1;
    NSViewAnimation *_animation2;
    BOOL _fullscreen;
}

- (id)initWithView:(NSView *)view;

// This is just a delegate that is being owned by the fullscreen controller.
@property (readwrite, retain) id <VLCFullscreenHUD> hud;

@property (readwrite, assign) id <VLCFullscreenDelegate> delegate;
@property (readonly, assign) BOOL fullscreen;

- (void)enterFullscreen:(NSScreen *)screen;
- (void)leaveFullscreen;
@end

@protocol VLCFullscreenHUD <NSObject>
- (void)fullscreenController:(VLCFullscreenController *)controller didEnterFullscreen:(NSScreen *)screen;
- (void)fullscreenControllerWillLeaveFullscreen:(VLCFullscreenController *)controller;
@end

@protocol VLCFullscreenDelegate <NSObject>
- (void)fullscreenControllerDidLeaveFullscreen:(VLCFullscreenController *)controller;
@end


