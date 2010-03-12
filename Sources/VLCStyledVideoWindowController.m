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
#import "VLCStyledVideoWindow.h"
#import "VLCStyledVideoWindowView.h"
#import "VLCMediaDocument.h"
#import "VLCStyledFullscreenHUDWindowController.h"
#import "VLCDocumentController.h"

static inline BOOL debugStyledWindow(void)
{
    return [VLCStyledVideoWindow debugStyledWindow];
}

#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
@interface VLCStyledVideoWindowController () <VLCFullscreenDelegate, NSWindowDelegate>
@end
#else
@interface VLCStyledVideoWindowController () <VLCFullscreenDelegate>
@end
#endif

@implementation VLCStyledVideoWindowController
@synthesize videoView=_videoView;
@synthesize styledWindowView=_styledWindowView;

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
        [_fullscreenController setDelegate:self];
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

    [window center];

    // FIXME - do it only if theme requires it
    VLCAssert(_accessoryButton, @"There should be an accessory view");

    NSView *themeFrame = [[window contentView] superview];
    NSSize size = [_accessoryView frame].size;
    NSSize frameSize = [themeFrame bounds].size;
    [_accessoryView setFrame:NSMakeRect(frameSize.width - size.width, frameSize.height - size.height, size.width, size.height)];
    [themeFrame addSubview:_accessoryView];
    [_accessoryButton bind:@"title" toObject:_styledWindowView withKeyPath:@"listCountString" options:nil];
    [_accessoryButton bind:@"value" toObject:_styledWindowView withKeyPath:@"showPlaylist" options:nil];

    [window setMovableByWindowBackground:YES];

    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSNullPlaceholderBindingOption, nil];
    [_styledWindowView bind:@"viewedPlaying" toObject:self withKeyPath:@"document.mediaListPlayer.mediaPlayer.playing" options:options];
    [_styledWindowView bind:@"mediaPlayerState" toObject:self withKeyPath:@"document.mediaListPlayer.mediaPlayer.state" options:options];
    [_styledWindowView bind:@"seekable" toObject:self withKeyPath:@"document.mediaListPlayer.mediaPlayer.seekable" options:options];
    options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:0], NSNullPlaceholderBindingOption, nil];
    [_styledWindowView bind:@"listCount" toObject:self withKeyPath:@"document.mediaListPlayer.mediaList.media.@count" options:options];
    [_styledWindowView bind:@"sublistCount" toObject:self withKeyPath:@"document.mediaListPlayer.rootMedia.subitems.media.@count" options:options];

    // To make sure there is no glitches, make sure the window is on screen, but hidden.
    [window setAlphaValue:0];
    [window makeKeyAndOrderFront:self];

    [_styledWindowView setup];
}

- (void)close
{
    [_styledWindowView close];
    // Detach ourselves from the fullscreen controller which may be still running on its own.
    _fullscreenController.delegate = nil;
    [_fullscreenController release];
    _fullscreenController = nil;
    [super close];
}

- (void)showWindow:(id)sender
{
    // Don't makeKeyAndOrderFront, we'll do that from the StyledWindowView

    // Because our window is borderless this is not properly done by NSDocument.
    // Work around by doing it ourselves.
    NSWindow *window = [self window];
    [NSApp addWindowsItem:window title:[window title] filename:NO];
}

- (void)setHasError:(CGFloat)alpha
{
    [_styledWindowView windowDidChangeAlphaValue:alpha];
}

#pragma mark -

- (void)setStyleWantsCocoaTitleBar:(BOOL)titleBar
{
    NSWindow *window = [self window];
    if (!debugStyledWindow() && !titleBar) {
        [window setBackgroundColor:[NSColor clearColor]];
        [window setHasShadow:NO];
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
        [window setStyleMask:NSBorderlessWindowMask];
#endif
    }
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    else
    {
        [window setHasShadow:YES];
        [window setStyleMask:NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask];
    }
#endif
}

#pragma mark -
#pragma mark fullscreen Delegate

- (void)fullscreenControllerDidLeaveFullscreen:(VLCFullscreenController *)controller
{
    [_fullscreenController autorelease];
    _fullscreenController = nil;
}

#pragma mark -
#pragma mark Window Delegate

- (NSRect)window:(NSWindow *)window willPositionSheet:(NSWindow *)sheet usingRect:(NSRect)rect
{
    NSRect frame = [_styledWindowView representedWindowRect];
    if (NSIsEmptyRect(frame))
        return rect;

    rect.size.width = MIN(NSWidth(rect), NSWidth(frame));
    rect.origin.x = NSMinX(frame);
    rect.origin.y = NSMinY(frame) + NSHeight(frame) - 22;
    return rect;
}

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
    [_styledWindowView setMainWindow:NO];
}

- (void)window:(NSWindow *)window didChangeAlphaValue:(CGFloat)alpha
{
    [_styledWindowView windowDidChangeAlphaValue:alpha];
}

- (NSRect)windowWillUseStandardFrame:(NSWindow *)window defaultFrame:(NSRect)newFrame
{
    NSRect standardFrame = [[window screen] frame];
    standardFrame.size.height -= [[NSApp menu] menuBarHeight];
    return standardFrame;
}

#pragma mark -
#pragma mark First responder handler (Respond to menu)

- (void)toggleFullscreen:(id)sender
{
    VLCFullscreenController *controller = [self fullscreenController];
    if (![controller fullscreen])
        [controller enterFullscreen:[[self window] screen]];
    else
        [controller leaveFullscreen];
}

- (void)toggleFloatingWindow:(id)sender
{
    NSWindow *window = [self window];
    NSInteger level = [window level];

    if (level == NSFloatingWindowLevel) {
        [window setLevel:NSNormalWindowLevel];
        [sender setState:NSOffState];
    } else {
        [window setLevel:NSFloatingWindowLevel];
        [sender setState:NSOnState];
    }
}

#pragma mark -
#pragma mark Javascript brigding

- (void)enterFullscreen
{
    [[self fullscreenController] enterFullscreen:[[self window] screen]];
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)sel
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
