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

#import "VLCStyledVideoWindowController.h"
#import "VLCStyledVideoWindowView.h"
#import "VLCMediaDocument.h"
#import "VLCStyledFullscreenHUDWindowController.h"

@implementation VLCStyledVideoWindowController
@synthesize videoView=_videoView;
- (void)dealloc
{
    [super dealloc];
}

- (VLCFullscreenController *)fullscreenController
{
    if (!_fullscreenController) {
        _fullscreenController = [[VLCFullscreenController alloc] initWithView:_videoView];
        VLCStyledFullscreenHUDWindowController *hud = [[VLCStyledFullscreenHUDWindowController alloc] init];
        [[self document] addWindowController:hud];
        _fullscreenController.hud = hud;
        [hud release];
    }
    return _fullscreenController;
}

- (VLCMediaDocument *)mediaDocument
{
    return (VLCMediaDocument *)[self document];
}

- (VLCMediaPlayer *)mediaPlayer
{
    return [self mediaDocument].mediaListPlayer.mediaPlayer;
}

- (NSString *)windowNibName
{
	return @"StyledVideoWindow";
}

- (void)windowDidLoad
{
    [super windowDidLoad];
	NSWindow * window = [self window];
    [window setDelegate:self];
    [_styledWindowView bind:@"currentTime" toObject:self withKeyPath:@"document.mediaListPlayer.mediaPlayer.time" options:nil];
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:0], NSNullPlaceholderBindingOption, nil];
    [_styledWindowView bind:@"viewedPosition" toObject:self withKeyPath:@"document.mediaListPlayer.mediaPlayer.position" options:options];
    options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSNullPlaceholderBindingOption, nil];
    [_styledWindowView setViewedPlaying:[[self valueForKeyPath:@"document.mediaListPlayer.mediaPlayer.playing"] boolValue]];
    [_styledWindowView bind:@"viewedPlaying" toObject:self withKeyPath:@"document.mediaListPlayer.mediaPlayer.playing" options:options];
}

- (void)close
{
    [_fullscreenController release];
    _fullscreenController = nil;
    [super close];
}

#pragma mark -
#pragma mark Window Delegate

- (void)windowDidBecomeKey:(NSNotification *)notification
{
    [_styledWindowView setKeyWindow:YES];
}
- (void)windowDidResignKey:(NSNotification *)notification
{
    [_styledWindowView setKeyWindow:NO];
}
- (void)windowDidBecomeMain:(NSNotification *)notification
{
    [_styledWindowView setMainWindow:YES];
}
- (void)windowDidResignMain:(NSNotification *)notification
{
    [_styledWindowView setMainWindow:YES];
}

#pragma mark -
#pragma mark Javascript brigding

- (void)enterFullscreen
{
    [[self fullscreenController] enterFullscreen:[[self window] screen]];
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)sel;
{
    if (sel == @selector(enterFullscreen))
        return NO;
    if (sel == @selector(window))
        return NO;
    
    return YES;
}

+ (BOOL)isKeyExcludedFromWebScript:(const char *)name
{
    return YES;
}

@end
