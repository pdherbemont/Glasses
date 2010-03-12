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

#import "VLCStyledFullscreenHUDWindowController.h"


@implementation VLCStyledFullscreenHUDWindowController

- (NSString *)windowNibName
{
	return @"StyledFullscreenHUDWindow";
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    VLCAssert(_styledWindowView, @"_styledWindowView is not properly set in Nib file");
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSNullPlaceholderBindingOption, nil];
    [_styledWindowView bind:@"viewedPlaying" toObject:self withKeyPath:@"document.mediaListPlayer.mediaPlayer.playing" options:options];
    [_styledWindowView bind:@"mediaPlayerState" toObject:self withKeyPath:@"document.mediaListPlayer.mediaPlayer.state" options:options];
    [_styledWindowView bind:@"seekable" toObject:self withKeyPath:@"document.mediaListPlayer.mediaPlayer.seekable" options:options];
    options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:0], NSNullPlaceholderBindingOption, nil];
    [_styledWindowView bind:@"listCount" toObject:self withKeyPath:@"document.mediaListPlayer.mediaList.media.@count" options:options];
    [_styledWindowView bind:@"sublistCount" toObject:self withKeyPath:@"document.mediaListPlayer.rootMedia.subitems.media.@count" options:options];
}

- (void)close
{
    [_styledWindowView close];
    [super close];
}

#pragma mark -
#pragma mark VLCFullscreenHUD protocol

- (void)fullscreenController:(VLCFullscreenController *)controller didEnterFullscreen:(NSScreen *)screen
{
    _fullscreenController = controller;
    NSWindow *window = [self window];
    VLCAssert(window, @"There is no window associated to this windowController. Check the .xib files.");
    [window setFrame:[screen frame] display:NO];
    [window makeKeyAndOrderFront:self];
}

- (void)fullscreenControllerWillLeaveFullscreen:(VLCFullscreenController *)controller
{
    [self close];
}

#pragma mark -
#pragma mark First responder handler (Respond to menu)

- (void)toggleFullscreen:(id)sender
{
    [_fullscreenController leaveFullscreen];
}

#pragma mark -
#pragma mark Javascript brigding

- (void)leaveFullscreen
{
    [_fullscreenController leaveFullscreen];
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)sel
{
    if (sel == @selector(leaveFullscreen))
        return NO;
    return YES;
}

+ (BOOL)isKeyExcludedFromWebScript:(const char *)name
{
    return YES;
}
@end
