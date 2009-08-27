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
#import "VLCExtendedVideoView.h"
#import "VLCStyledVideoWindow.h"
#import "DOMElement_Additions.h"

@interface  VLCStyledVideoWindowView ()
- (void)videoDidResize;
@end

@implementation VLCStyledVideoWindowView
- (void)dealloc
{
    NSAssert(!_contentTracking, @"_contentTracking should have been released");
    NSAssert(!_videoWindow, @"_videoWindow should have been released");
    [super dealloc];
}

- (void)close
{
    [_videoWindow close];
    [_videoWindow release];
    _videoWindow = nil;
    [self removeTrackingArea:_contentTracking];
    [_contentTracking release];
    _contentTracking = nil;
    [super close];
}

- (void)awakeFromNib
{
    [self setup];    
}

- (NSString *)pageName
{
    return @"video-window";
}

- (void)didFinishLoadForFrame:(WebFrame *)frame
{
    [super didFinishLoadForFrame:frame];

    NSWindow *window = [self window];
    [[self windowScriptObject] setValue:window forKey:@"PlatformWindow"];

    [self videoDidResize];
    [self setKeyWindow:[window isKeyWindow]];
    [self setMainWindow:[window isMainWindow]];
    [self updateTrackingAreas];
    
    [window performSelector:@selector(invalidateShadow) withObject:self afterDelay:0.];
}

#pragma mark -
#pragma mark Core -> Javascript setters

- (void)setKeyWindow:(BOOL)isKeyWindow
{
    if (isKeyWindow)
        [self addClassToContent:@"key-window"];
    else
        [self removeClassFromContent:@"key-window"];

}

- (void)setMainWindow:(BOOL)isMainWindow
{
    if (isMainWindow)
        [self addClassToContent:@"main-window"];
    else
        [self removeClassFromContent:@"main-window"];
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

#define SUPPORT_VIDEO_BELOW_CONTENT 0

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

- (void)videoDidResize
{
    // This synchronize the VLCVideoView on top of the element whose id is "video-view"
    // We actually put the VLCVideoView in a Window that will be a child window,
    // Hence the HTML content will be able to overlay the window.

    DOMHTMLElement *element = [self htmlElementForId:@"video-view"];
    NSAssert(element, @"No video-view element in this style");
    VLCVideoView *videoView = [[[self window] windowController] videoView];
    NSAssert(videoView, @"There is no videoView.");

    NSRect frame = [element frameInView:self];
#if SUPPORT_VIDEO_BELOW_CONTENT
    NSRect screenRect = screenRectForViewRect(self, frame);

    BOOL belowContent = [element.className rangeOfString:@"below-content"].length > 0;
    NSWindow *window = [self window];
    if (![videoView window]) {
        
        // Create the window now.
        _videoWindow = [[NSWindow alloc] initWithContentRect:screenRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES];
        [_videoWindow setBackgroundColor:[NSColor blackColor]];
        [_videoWindow setLevel:VLCFullscreenHUDWindowLevel];
        [_videoWindow setContentView:videoView];
        [_videoWindow setIgnoresMouseEvents:YES];
        [window addChildWindow:_videoWindow ordered:belowContent ? NSWindowBelow : NSWindowAbove];
    }
    else {
        //[[self window] removeChildWindow:_videoWindow];
        BOOL videoWindowIsOnTop = [_videoWindow windowNumber] < [window windowNumber];
        if (videoWindowIsOnTop ^ belowContent)
            [window addChildWindow:_videoWindow ordered:belowContent ? NSWindowBelow : NSWindowAbove];
        [_videoWindow setFrame:screenRect display:NO];
    }

#else
    if (![videoView superview])
        [self addSubview:videoView];
    [videoView setFrame:frame];
#endif
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)sel;
{
    if (sel == @selector(videoDidResize))
        return NO;
    if (sel == @selector(play))
        return NO;
    if (sel == @selector(pause))
        return NO;
    if (sel == @selector(setPosition:))
        return NO;
    
    return YES;
}

+ (BOOL)isKeyExcludedFromWebScript:(const char *)name
{
    return YES;
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
    if (!_isFrameLoaded) {
        [super updateTrackingAreas];
        return;
    }

    // Don't track ignored mouseEvents in debug window
   if ([VLCStyledVideoWindow debugStyledWindow])
       return;

    DOMElement *element = [self htmlElementForId:@"content"];
    NSAssert(element, @"No content element in this style");
    NSRect frame = [element frameInView:self];
    
    if (!_contentTracking || !NSEqualRects([_contentTracking rect], frame)) {
        [self removeTrackingArea:_contentTracking];
        [_contentTracking release];
        _contentTracking = [[NSTrackingArea alloc] initWithRect:frame options:NSTrackingMouseEnteredAndExited|NSTrackingActiveAlways owner:self userInfo:nil];    
        [self addTrackingArea:_contentTracking];
    }
    
    [super updateTrackingAreas];
}


#pragma mark -
#pragma mark View methods

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (NSView *)hitTest:(NSPoint)point
{
    // Hit test function that ignores the videoView and forward everything
    // to the webview. This allows a full control over the behaviour of event
    // in the video view by the style.

    NSView *videoView = [[[self window] windowController] videoView];
    for (NSView *subview in [self subviews])
    {
        if (subview == videoView)
            continue;
        NSPoint localPoint = [subview convertPoint:point fromView:self];
        NSView *result = [subview hitTest:localPoint];
        if (result)
            return result;
    }

    return NSPointInRect(point, [self bounds]) ? self : nil;
}

@end
