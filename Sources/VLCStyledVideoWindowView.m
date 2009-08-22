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

- (VLCMediaPlayer *)mediaPlayer
{
    return [[[self window] windowController] mediaPlayer];
}

#pragma mark -
#pragma mark Javascript callbacks

- (void)setPosition:(float)position
{
    NSLog(@"%f", position);
    [[self mediaPlayer] setPosition:position];
}

- (void)play
{    
    [[self mediaPlayer] play];
}

- (void)toggleFullscreen
{
    VLCExtendedVideoView *videoView = [[[self window] windowController] videoView];
	[videoView setFullscreen:![videoView fullscreen]];
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
    if (sel == @selector(toggleFullscreen))
        return NO;
    if (sel == @selector(play))
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
    [win setValue:[self window] forKey:@"PlatformWindow"];
    [win setValue:self forKey:@"PlatformView"];

    [self videoDidResize];
    [self setKeyWindow:[[self window] isKeyWindow]];
    [self setMainWindow:[[self window] isMainWindow]];
    [self setWindowTitle:[[self window] title]];
    [self updateTrackingAreas];
}

#pragma mark -
#pragma mark Tracking area

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
