//
//  VLCFullscreenHUDWindow.m
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

#import "VLCFullscreenHUDWindow.h"


@implementation VLCFullscreenHUDWindow

- (id)initWithContentRect:(NSRect)contentRect 
                styleMask:(unsigned int)aStyle 
                  backing:(NSBackingStoreType)bufferingType 
                    defer:(BOOL)flag
{
    if (self = [super initWithContentRect:contentRect styleMask:NSTexturedBackgroundWindowMask backing:bufferingType defer:flag]) {
        [self setOpaque:NO];
        [self setHasShadow: NO];
        [self setBackgroundColor:[NSColor clearColor]];
		[self setHidesOnDeactivate:YES];
        
        /* let the window sit on top of everything else and start out completely transparent */
        [self setLevel:NSFloatingWindowLevel];
    }
    return self;
}

-(void)center
{
    /* user-defined screen */
        
    NSRect screenFrame = [[NSScreen mainScreen] frame];
    NSRect windowFrame = [self frame];
    NSPoint coordinate;
    coordinate.x = (windowFrame.size.width - windowFrame.size.width) / 2 + screenFrame.origin.x;
    coordinate.y = (windowFrame.size.height / 3) - windowFrame.size.height + screenFrame.origin.y;
    [self setFrameTopLeftPoint:coordinate];
}

@end
