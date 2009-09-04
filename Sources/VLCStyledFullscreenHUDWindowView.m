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

#import "VLCMediaDocument.h"

@implementation VLCStyledFullscreenHUDWindowView

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

#pragma mark -
#pragma mark Javascript callbacks

- (void)setPosition:(float)position
{
    [[self mediaPlayer] setPosition:position];
}

- (void)play
{
    [[self mediaPlayer] play];
}

- (void)pause
{
    [[self mediaPlayer] pause];
}

- (void)hideCursorUntilMouseMoves
{
    [NSCursor setHiddenUntilMouseMoves:YES];
}

- (VLCMediaListPlayer *)mediaListPlayer
{
    return [[[[self window] windowController] document] mediaListPlayer];
}


- (VLCMediaList *)rootMediaList
{
    VLCMediaListPlayer *player = [self mediaListPlayer];
    VLCMediaList *mainMediaContent = player.rootMedia.subitems;
    BOOL isPlaylistDocument = mainMediaContent.count > 0;
    return isPlaylistDocument ? mainMediaContent : player.mediaList;
}

- (void)playMediaAtIndex:(NSUInteger)index
{
    [[self mediaListPlayer] playMedia:[[self rootMediaList] mediaAtIndex:index]];
}

- (NSString *)titleAtIndex:(NSUInteger)index
{
    return [[[self rootMediaList] mediaAtIndex:index].metaDictionary objectForKey:@"title"];
}

- (NSUInteger)count
{
    return [[self rootMediaList] count];
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)sel
{
    if (sel == @selector(playMediaAtIndex:))
        return NO;
    if (sel == @selector(titleAtIndex:))
        return NO;
    if (sel == @selector(count))
        return NO;    
    if (sel == @selector(play))
        return NO;
    if (sel == @selector(pause))
        return NO;
    if (sel == @selector(setPosition:))
        return NO;
    if (sel == @selector(hideCursorUntilMouseMoves))
        return NO;
    return YES;
}

+ (BOOL)isKeyExcludedFromWebScript:(const char *)name
{
    return YES;
}

@end
