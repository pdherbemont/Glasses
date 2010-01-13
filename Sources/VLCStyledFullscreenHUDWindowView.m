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

#import <VLCKit/VLCKit.h>

#import "VLCStyledFullscreenHUDWindowView.h"
#import "VLCStyledFullscreenHUDWindowController.h"

#import "VLCMediaDocument.h"

@implementation VLCStyledFullscreenHUDWindowView

- (void)close
{
    [super close];
}

- (void)setup
{
    [super setup];
}

- (void)awakeFromNib
{
    [self setup];
}

- (NSString *)pageName
{
    return @"hud";
}

- (void)didFinishLoadForFrame:(WebFrame *)frame
{
    [super didFinishLoadForFrame:frame];

    // Make sure the cursor is hidden, at this point the js is
    // ready to handle the cursor visibility.
    [NSCursor setHiddenUntilMouseMoves:YES];
}

- (void)cancelOperation:(id)sender
{
    [[[self window] windowController] leaveFullscreen];
}

- (void)mouseDown:(NSEvent *)event
{
	if ([event clickCount] == 2)
		[[[self window] windowController] leaveFullscreen];
    else
        [super mouseDown:event];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event
{
    return YES;
}

- (void)keyDown:(NSEvent *)theEvent
{

}

- (void)hideCursorUntilMouseMoves
{
    [NSCursor setHiddenUntilMouseMoves:YES];
}

#pragma mark -
#pragma mark Javascript callbacks

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)sel
{
    if (sel == @selector(hideCursorUntilMouseMoves))
        return NO;
    if ([super respondsToSelector:@selector(isSelectorExcludedFromWebScript:)])
        return [super isSelectorExcludedFromWebScript:sel];
    return YES;
}

+ (NSString *)webScriptNameForSelector:(SEL)sel
{
    if ([super respondsToSelector:@selector(webScriptNameForSelector:)])
        return [super webScriptNameForSelector:sel];
    return nil;
}

+ (BOOL)isKeyExcludedFromWebScript:(const char *)name
{
    return YES;
}

@end
