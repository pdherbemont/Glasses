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
- (NSString *)_contentHTML;
- (NSURL *)_baseURL;
- (void)_addClassToContent:(NSString *)class;
- (void)_removeClassFromContent:(NSString *)class;
- (DOMHTMLElement *)_htmlElementForId:(NSString *)idName;
@end

@implementation VLCStyledVideoWindowView
- (void)dealloc
{
    NSAssert(!_contentTracking, @"_contentTracking should have been released");
    [super dealloc];
}

- (void)close
{
    [self removeTrackingArea:_contentTracking];
    [_contentTracking release];
    _contentTracking = nil;
    [super close];
}

- (void)awakeFromNib
{
    [self setup];    
}

- (void)setup
{
    [self setDrawsBackground:NO];
    
    [self setFrameLoadDelegate:self];
    [self setUIDelegate:self];
    [self setResourceLoadDelegate:self];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"template" ofType:@"html"];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:path] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:5.];
    [[self mainFrame] loadRequest:request];    
}

- (VLCMediaPlayer *)mediaPlayer
{
    return [[[self window] windowController] mediaPlayer];
}

#pragma mark -
#pragma mark Methods that are acting on the interface (ie: on javascript code).

- (void)setKeyWindow:(BOOL)isKeyWindow
{
    if (isKeyWindow)
        [self _addClassToContent:@"key-window"];
    else
        [self _removeClassFromContent:@"key-window"];

}

- (void)setMainWindow:(BOOL)isMainWindow
{
    if (isMainWindow)
        [self _addClassToContent:@"main-window"];
    else
        [self _removeClassFromContent:@"main-window"];
}

- (void)setWindowTitle:(NSString *)title
{
    if (!_isFrameLoaded)
        return;
    DOMHTMLElement *windowTitle = [self _htmlElementForId:@"window-title"];
    windowTitle.innerText = title;
}

- (void)setEllapsedTime:(NSString *)ellapsedTime
{
    if (!_isFrameLoaded)
        return;
    DOMHTMLElement *timeField = [self _htmlElementForId:@"ellapsed-time"];
    timeField.innerText = ellapsedTime;
}

- (NSString *)ellapsedTime
{
    return _isFrameLoaded ? [self _htmlElementForId:@"ellapsed-time"].innerText : @"";
}

// The viewedPosition value is set from the core to indicate a the position of the
// playing media.
// This is different from the setPosition: method that is being called by the
// javascript bridge (ie: from the interface code)
- (void)setViewedPosition:(float)position
{
    if (!_isFrameLoaded)
        return;
    DOMHTMLElement *element = [self _htmlElementForId:@"timeline"];
    [element setAttribute:@"value" value:[NSString stringWithFormat:@"%.0f", position * 1000]];
    _viewedPosition = position;
}

- (float)viewedPosition
{
    return _viewedPosition;
}

- (void)setViewedPlaying:(BOOL)isPlaying
{
    if (!_isFrameLoaded)
        return;
    if (isPlaying == _viewedPlaying)
        return;
    _viewedPlaying = isPlaying;

    if (isPlaying)
        [self _addClassToContent:@"playing"];
    else
        [self _removeClassFromContent:@"playing"];
}

- (BOOL)viewedPlaying
{
    return _viewedPlaying;
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

- (void)videoDidResize
{    
    DOMElement *element = [[[self mainFrame] DOMDocument] getElementById:@"video-view"];
    NSAssert(element, @"No video-view element in this style");
    VLCVideoView *videoView = [[[self window] windowController] videoView];
    NSAssert(videoView, @"There is no videoView.");

    NSRect frame = [element frameInView:self];
    if (![videoView superview])
        [self addSubview:videoView];
    [videoView setFrame:frame];
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
#pragma mark WebViewDelegate

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
    _isFrameLoaded = YES;
    id win = [self windowScriptObject];
    NSWindow *window = [self window];
    [win setValue:[window windowController] forKey:@"PlatformWindowController"];
    [win setValue:window forKey:@"PlatformWindow"];
    [win setValue:self forKey:@"PlatformView"];

    [self videoDidResize];
    [self setKeyWindow:[window isKeyWindow]];
    [self setMainWindow:[window isMainWindow]];
    [self setWindowTitle:[window title]];
    [self updateTrackingAreas];

    [window performSelector:@selector(invalidateShadow) withObject:self afterDelay:0.];
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

    DOMElement *element = [[[self mainFrame] DOMDocument] getElementById:@"content"];
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
#pragma mark Menu Item Action

- (void)setStyleFromMenuItem:(id)sender
{
    NSAssert([sender isKindOfClass:[NSMenuItem class]], @"Only menu item are supported");
    NSMenuItem *item = sender;

    DOMHTMLElement *element = [self _htmlElementForId:@"style"];
    NSAssert([element isKindOfClass:[DOMHTMLLinkElement class]], @"Element 'style' should be a link");
    DOMHTMLLinkElement *link = (id)element;
    if ([[item title] isEqualToString:@"Orange"])
        link.href = @"orange.css";
    else if ([[item title] isEqualToString:@"Black"])
        link.href = @"black.css";
    else
        link.href = @"default.css";

    // Hack: Reload the full page for style change, this will help
    [[self window] performSelector:@selector(invalidateShadow) withObject:self afterDelay:0.25];
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

#pragma mark -
#pragma mark Private

- (DOMHTMLElement *)_htmlElementForId:(NSString *)idName;
{
    DOMElement *element = [[[self mainFrame] DOMDocument] getElementById:idName];
    NSAssert1([element isKindOfClass:[DOMHTMLElement class]], @"The '%@' element should be a DOMHTMLElement", idName);
    return (id)element;
}
                           
- (void)_addClassToContent:(NSString *)class
{
    if (!_isFrameLoaded)
        return;
    DOMHTMLElement *content = [self _htmlElementForId:@"content"];
    NSString *currentClassName = content.className;
    
    if (!currentClassName)
        content.className = class;
    else if ([currentClassName rangeOfString:class].length == 0)
        content.className = [NSString stringWithFormat:@"%@ %@", content.className, class];
}

- (void)_removeClassFromContent:(NSString *)class
{
    if (!_isFrameLoaded)
        return;
    DOMHTMLElement *content = [self _htmlElementForId:@"content"];
    NSString *currentClassName = content.className;
    if (!currentClassName)
        return;
    NSRange range = [currentClassName rangeOfString:class];
    if (range.length > 0)
        content.className = [content.className stringByReplacingCharactersInRange:range withString:@""];
}

- (NSString *)_contentHTML
{
	return [NSString stringWithContentsOfURL:[self _baseURL] encoding:NSUTF8StringEncoding error:NULL];
}

- (NSURL *)_baseURL
{
	return [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"template" ofType:@"html"]];
}
@end
