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

#import "VLCStyledVideoWindow.h"

//#define DEBUG_STYLED_WINDOW

static inline BOOL debugStyledWindow(void)
{
    return [VLCStyledVideoWindow debugStyledWindow];
}

@implementation VLCStyledVideoWindow
+ (BOOL)debugStyledWindow
{
#ifdef DEBUG_STYLED_WINDOW
    return YES;
#endif
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"DebugStyledWindow"];    
}
- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag;
{
    if (!debugStyledWindow())
        aStyle = NSBorderlessWindowMask;
    self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag];
    if (!self)
        return nil;
    
    [self setMovableByWindowBackground:YES];
    if (!debugStyledWindow()) {
        [self setOpaque:NO];
        [self setBackgroundColor:[NSColor clearColor]];
    }
    [self setHasShadow:YES];
    [self setAcceptsMouseMovedEvents:YES];
    [self setIgnoresMouseEvents:NO];
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

// Because we are borderless, a certain number of thing don't work out of the box.
// For instance the NSDocument patterns don't apply, we have to reimplement them.
- (void)performClose:(id)sender
{
    NSDocument *doc = [[NSDocumentController sharedDocumentController] documentForWindow:self];
    [doc close];
}

- (void)performZoom:(id)sender
{
    [self zoom:nil];
    [NSApp updateWindowsItem:self];
}

- (void)performMiniaturize:(id)sender
{
    [self miniaturize:nil];
    [NSApp updateWindowsItem:self];
}

- (BOOL)validateUserInterfaceItem:(id < NSValidatedUserInterfaceItem >)anItem
{
    SEL sel = [anItem action];
    if (sel == @selector(performClose:))
        return YES;
    if (sel == @selector(performZoom:))
        return YES;
    if (sel == @selector(performMiniaturize:))
        return YES;
    return [super validateUserInterfaceItem:anItem];
}

#pragma mark -
#pragma mark Javascript bindings
/* Javascript bindings: We are not necessarily respecting Cocoa naming scheme convention. That's an exception */

- (void)performClose
{
    [self performClose:self];
}

- (void)zoom
{
    [super zoom:nil];
}

- (void)miniaturize
{
    [super miniaturize:nil];
}

- (float)frameOriginX
{
    return [self frame].origin.x;
}

- (float)frameOriginY
{
    return [self frame].origin.y;
}

- (void)setFrameOrigin:(float)x :(float)y
{
    [self setFrameOrigin:NSMakePoint(x, y)];
}

- (float)frameSizeHeight
{
    return [self frame].size.height;
}

- (float)frameSizeWidth
{
    return [self frame].size.width;
}

- (void)willStartLiveResize
{
    [[self contentView] viewWillStartLiveResize];
}

- (void)didEndLiveResize
{
    [[self contentView] viewDidEndLiveResize];
}

- (void)setFrame:(float)x :(float)y :(float)width :(float)height
{
    NSRect frame = [self frame];
    frame.origin.x = x;
    frame.origin.y = y;
    frame.size.height = height;
    frame.size.width = width;
    [self setFrame:frame display:YES];
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)sel;
{
    if (sel == @selector(performClose))
        return NO;
    if (sel == @selector(zoom))
        return NO;
    if (sel == @selector(miniaturize))
        return NO;
    if (sel == @selector(setFrameOrigin::))
        return NO;
    if (sel == @selector(frameOriginX))
        return NO;
    if (sel == @selector(frameOriginY))
        return NO;
    if (sel == @selector(setFrame::::))
        return NO;
    if (sel == @selector(frameSizeHeight))
        return NO;
    if (sel == @selector(frameSizeWidth))
        return NO;
    if (sel == @selector(willStartLiveResize))
        return NO;
    if (sel == @selector(didEndLiveResize))
        return NO;
    
    return YES;
}

+ (BOOL)isKeyExcludedFromWebScript:(const char *)name
{
    return YES;
}

@end
