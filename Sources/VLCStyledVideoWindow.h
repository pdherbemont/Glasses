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

@interface VLCStyledVideoWindow : NSWindow {
    NSWindowController *_windowController;
    NSRect _unzoomedRect;
}
+ (BOOL)debugStyledWindow;

@end

#ifdef SUPPORT_VIDEO_BELOW_CONTENT
// In SL this is not the proper way to do it,
// we have to switch to @protocol VLCStyledVideoWindow <NSWindowDelegate>
@interface NSObject (VLCStyledVideoWindowDelegate)
- (void)window:(NSWindow *)window didChangeAlphaValue:(CGFloat)alpha;
@end
#endif
