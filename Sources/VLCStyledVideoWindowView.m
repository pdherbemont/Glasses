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

#import "VLCStyledVideoWindowView.h"
#import "VLCStyledVideoWindowController.h"
#import "VLCStyledVideoWindow.h"
#import "VLCMediaDocument.h"
#import "DOMElement_Additions.h"
#import "DOMHTMLElement_Additions.h"

@interface  VLCStyledVideoWindowView ()
- (void)videoDidResize;
- (void)_removeBelowWindow;
@end

@implementation VLCStyledVideoWindowView
- (void)dealloc
{
    VLCAssert(!_contentTracking, @"_contentTracking should have been released");
    VLCAssert(!_videoWindow, @"_videoWindow should have been released");
    VLCAssert(!_containerForVideoView, @"_containerForVideoView should have been released");
    [super dealloc];
}

- (void)close
{
#if SUPPORT_VIDEO_BELOW_CONTENT
    [self _removeBelowWindow];
#endif
    if (_contentTracking) {
        [self removeTrackingArea:_contentTracking];
        [_contentTracking release];
        _contentTracking = nil;
    }

    [_containerForVideoView release];
    _containerForVideoView = nil;
    [super close];
}

- (void)setup
{
#if SUPPORT_VIDEO_BELOW_CONTENT
    // When a style is reloaded, this method gets called.
    // Clear the below window here.
    [self _removeBelowWindow];
#endif
    [super setup];
}

- (NSString *)pageName
{
    // video-window.html is the name of the file we are interested in.
    return @"video-window";
}

- (BOOL)mouseDownCanMoveWindow
{
    return YES;
}

- (void)didFinishLoadForFrame:(WebFrame *)frame
{
    BOOL enterFS = [[NSUserDefaults standardUserDefaults] boolForKey:kStartPlaybackInFullscreen];
    NSWindow *window = [self window];

    // Make sure we remove the videoView from superview or from the below window
    // hence, we'll be able to properly recreate it.
    [self _removeBelowWindow];
    [_containerForVideoView removeFromSuperview];

    [[self windowScriptObject] setValue:window forKey:@"PlatformWindow"];

    [window setIgnoresMouseEvents:NO];

    [self videoDidResize];

    // Time to go fullscreen, this can't be done before,
    // because we need (for fullscreen exit) to have the video view
    // properly setuped. A bit of coding could fix that, but that's enough
    // for now.
    if (enterFS && ![self hasLoadedAFirstFrame]) {
        [window orderOut:self];
        [[window windowController] enterFullscreen];
    }

    // The following will make the window visible (alpha = 1)
    [super didFinishLoadForFrame:frame];

    // Sync with what this theme needs in term of window
    _isStyleOpaque = ![self contentHasClassName:@"transparent"];
    if ([window isOpaque] != _isStyleOpaque)
        [window setOpaque:_isStyleOpaque];

    VLCStyledVideoWindowController *controller = [window windowController];
    BOOL wantsCocoaTitleBar = [self contentHasClassName:@"wants-cocoatitlebar"];
    [controller setStyleWantsCocoaTitleBar:wantsCocoaTitleBar];

    if (!enterFS || [self hasLoadedAFirstFrame])
        [window makeKeyAndOrderFront:self];

    [self setKeyWindow:[window isKeyWindow]];
    [self setMainWindow:[window isMainWindow]];
    [self updateTrackingAreas];

    // Make sure we don't loose the first responder. Else the style menu will not
    // work. You can reproduce this when using a borderless window.
    [window makeFirstResponder:self];
}

- (void)windowDidChangeAlphaValue:(CGFloat)alpha
{
    [_videoWindow setAlphaValue:alpha];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event
{
    return YES;
}

- (NSRect)representedWindowRect
{
    DOMElement *element = [self htmlElementForId:@"main-window" canBeNil:YES];

    NSRect frame = element ? [element frameInView:self] : NSZeroRect;

    DOMHTMLElement *more = [self htmlElementForId:@"more" canBeNil:YES] ;
    if (more && [more hasClassName:@"visible"]) {
        NSRect frameMore = [more frameInView:self];
        frame = NSUnionRect(frameMore, frame);
    }
    return frame;
}

#pragma mark -
#pragma mark Core -> Javascript setters

- (void)setKeyWindow:(BOOL)isKeyWindow
{
    if (![self isFrameLoaded])
        return;
    if (isKeyWindow)
        [self addClassToContent:@"key-window"];
    else
        [self removeClassFromContent:@"key-window"];

}

- (void)setMainWindow:(BOOL)isMainWindow
{
    if (![self isFrameLoaded])
        return;
    if (isMainWindow)
        [self addClassToContent:@"main-window"];
    else
        [self removeClassFromContent:@"main-window"];
}

// Other setter are in super class.

#pragma mark -
#pragma mark Javascript callbacks

#if SUPPORT_VIDEO_BELOW_CONTENT
static NSRect screenRectForViewRect(NSView *view, NSRect rect)
{
    NSRect screenRect = [view convertRect:rect toView:nil]; // Convert to Window base coord
    NSRect windowFrame = [[view window] frame];
    screenRect.origin.x += windowFrame.origin.x;
    screenRect.origin.y += windowFrame.origin.y;
    return screenRect;
}
#endif

- (void)_removeBelowWindow
{
    if (_videoWindow)
        [[self window] removeChildWindow:_videoWindow];
    [_videoWindow close];
    [_videoWindow release];
    _videoWindow = nil;
}

- (void)_addBelowWindowInRect:(NSRect)screenRect withView:(NSView *)view
{
    VLCAssert(!_videoWindow, @"There should not be a video window at this point");

    // Create the window now.
    _videoWindow = [[NSWindow alloc] initWithContentRect:screenRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES];
    [_videoWindow setBackgroundColor:[NSColor blackColor]];
    [_videoWindow setLevel:VLCFullscreenHUDWindowLevel()];
    [_videoWindow setContentView:view];
    [_videoWindow setIgnoresMouseEvents:YES];
    [_videoWindow setReleasedWhenClosed:NO];
    [_videoWindow setAcceptsMouseMovedEvents:NO];
    [_videoWindow setHasShadow:YES];
    NSWindow *window = [self window];
    [_videoWindow setAlphaValue:[window alphaValue]];
    [window addChildWindow:_videoWindow ordered:NSWindowBelow];
}

- (void)videoDidResize
{
    FROM_JS();

    // This synchronize the VLCVideoView on top of the element whose id is "video-view"
    // When the style wants the video-view to be below the rest of the page, we
    // put the VLCVideoView in a Window that will be a child window.
    // Hence the HTML content will be able to overlay the window.
    //
    // When there is no such instruction, it will just be a regular NSView in the
    // parent window.

    // First, fast path for the liveresize case when there is no belowwindow.
    if (!_videoWindow && [self inLiveResize]) {
        return;
    }

    DOMHTMLElement *element = [self htmlElementForId:@"video-view"];
    VLCAssert(element, @"No video-view element in this style");

    if (!_containerForVideoView) {
        NSView *videoView = [[[self window] windowController] videoView];
        VLCAssert(videoView, @"There is no videoView.");
        _containerForVideoView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 128, 128)];
        [_containerForVideoView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [videoView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [_containerForVideoView addSubview:videoView];
        [videoView setFrame:[_containerForVideoView bounds]];
    }

    NSRect frame = [element frameInView:self];

    if (![self inLiveResize]) {
        // For now the playlist toggle uses this methog
        // to update the tracking area as well, so force it here.
        [self updateTrackingAreas];
    }

#if SUPPORT_VIDEO_BELOW_CONTENT
    BOOL wantsBelowContent = [element.className rangeOfString:@"below-content"].length > 0;
    if (![_containerForVideoView window]) {

        if (wantsBelowContent) {
            [self _addBelowWindowInRect:screenRectForViewRect(self, frame) withView:_containerForVideoView];
        }
        else {
            [self addSubview:_containerForVideoView];
            [_containerForVideoView setFrame:frame];
        }

    }
    else {
        BOOL videoIsOnTop = !_videoWindow;
        if (videoIsOnTop && !wantsBelowContent) {
            [_containerForVideoView setFrame:frame];
            return;
        }
        if (!videoIsOnTop && wantsBelowContent) {
            [_videoWindow setFrame:screenRectForViewRect(self, frame) display:YES];
            return;
        }
        if (videoIsOnTop && wantsBelowContent) {
            [_containerForVideoView removeFromSuperviewWithoutNeedingDisplay];
            [self _addBelowWindowInRect:screenRectForViewRect(self, frame) withView:_containerForVideoView];
            return;
        }
        if (!videoIsOnTop && !wantsBelowContent) {
            [_containerForVideoView removeFromSuperviewWithoutNeedingDisplay];
            [self addSubview:_containerForVideoView];
            [_containerForVideoView setFrame:frame];
            [self _removeBelowWindow];
            return;
        }
        VLCAssertNotReached(@"Previous conditions should not lead here");
    }
#else
    if (![_containerForVideoView superview])
        [self addSubview:_containerForVideoView];
    [_containerForVideoView setFrame:frame];
#endif
    RETURN_NOTHING_TO_JS();
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)sel
{
    if (sel == @selector(videoDidResize))
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

- (BOOL)isOpaque
{
    return _isStyleOpaque;
}

#pragma mark -
#pragma mark Tracking area

// Because the NSWindow that contains our WebView might have a lot
// of transparent area, we need to restrict click event in those area.
// The transparent area might be present because of some drop shadow.

- (void)mouseEntered:(NSEvent *)theEvent
{
    [[self window] setIgnoresMouseEvents:NO];
}

- (void)mouseExited:(NSEvent *)theEvent
{
    [[self window] setIgnoresMouseEvents:YES];
}

- (void)updateTrackingAreas
{
    // We don't need to do special stuff if we are opaque.
    if (!_isFrameLoaded || [self isOpaque]) {
        if (_contentTracking) {
            [self removeTrackingArea:_contentTracking];
            [_contentTracking release];
            _contentTracking = nil;
            [[self window] setIgnoresMouseEvents:NO];
        }

        [super updateTrackingAreas];
        return;
    }

    // Don't track ignored mouseEvents in debug window
   if ([VLCStyledVideoWindow debugStyledWindow])
       return;

    NSRect frame = [self representedWindowRect];

    if (!_contentTracking || !NSEqualRects([_contentTracking rect], frame)) {
        [self removeTrackingArea:_contentTracking];
        [_contentTracking release];
        _contentTracking = [[NSTrackingArea alloc] initWithRect:frame options:NSTrackingMouseEnteredAndExited|NSTrackingActiveAlways|NSTrackingEnabledDuringMouseDrag owner:self userInfo:nil];
        [self addTrackingArea:_contentTracking];
    }

    NSWindow *window = [self window];
    NSRect locationInWindow = [self convertRect:frame toView:nil];
    NSPoint mouseInWindow = [window convertScreenToBase:[NSEvent mouseLocation]];
    BOOL isMouseActiveInWindow = NSPointInRect(mouseInWindow, locationInWindow);
    [window setIgnoresMouseEvents:!isMouseActiveInWindow];

    [super updateTrackingAreas];
}

#pragma mark -
#pragma mark View methods

- (BOOL)acceptsFirstResponder
{
    return YES;
}

@end
