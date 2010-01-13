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

#import "VLCStyledFullscreenHUDWindow.h"
#import "VLCStyledVideoWindow.h"
#import "VLCFullscreenController.h"
#import "VLCDocumentController.h"

static inline BOOL debugStyledWindow(void)
{
    return [VLCStyledVideoWindow debugStyledWindow];
}

@implementation VLCStyledFullscreenHUDWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)style backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
    self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:bufferingType defer:YES];
    if (!self)
        return nil;
    [self setOpaque:NO];
    if (debugStyledWindow())
        [self setBackgroundColor:[NSColor colorWithCalibratedRed:1 green:0 blue:0 alpha:0.5]];
    else
        [self setBackgroundColor:[NSColor clearColor]];
    [self setAcceptsMouseMovedEvents:YES];
    [self setIgnoresMouseEvents:NO];
    [self setLevel:VLCFullscreenHUDWindowLevel()];
    return self;
}

- (BOOL)canBecomeKeyWindow
{
    return YES;
}

- (BOOL)canBecomeMainWindow
{
    return YES;
}

- (void)becomeMainWindow
{
    [super becomeMainWindow];

    // -[NSDocumentController currentDocument] doesn't send Notification
    // when changed. Our Bindings (in MainWindow.xib) don't update as a result.
    // Post it here, and in -becomeMainWindow.
    // If you have a better work around, I am all for it.
    VLCDocumentController *controller = [NSDocumentController sharedDocumentController];
    [controller setMainWindow:self];
}

- (void)resignMainWindow
{
    // See -becomeMainWindow
    VLCDocumentController *controller = [NSDocumentController sharedDocumentController];
    [controller setMainWindow:nil];
    [super resignMainWindow];
}
@end
