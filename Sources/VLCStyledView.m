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

#import "VLCStyledView.h"
#import <VLCKit/VLCKit.h>
#import "VLCMediaDocument.h"

@interface VLCStyledView ()
@property (readwrite, assign) BOOL isFrameLoaded;
- (void)setInnerText:(NSString *)text forElementsOfClass:(NSString *)class;
- (void)setAttribute:(NSString *)attribute value:(NSString *)value forElementsOfClass:(NSString *)class;
- (NSURL *)url;
@end

@implementation VLCStyledView
@synthesize isFrameLoaded=_isFrameLoaded;

- (void)dealloc
{
    [_title release];
    [_currentTime release];
    [super dealloc];
}

- (void)setup
{
    [self setDrawsBackground:NO];
    
    [self setFrameLoadDelegate:self];
    [self setUIDelegate:self];
    [self setResourceLoadDelegate:self];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[self url] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:5.];
    [[self mainFrame] loadRequest:request];    
}

- (VLCMediaPlayer *)mediaPlayer
{
    return [[[[self window] windowController] document] mediaListPlayer].mediaPlayer;
}


- (NSString *)pageName
{
    VLCAssertNotReached(@"You must override -pageName in your subclass");
    return nil;
}

- (NSURL *)url
{
    NSString *pluginPath = [[[NSBundle mainBundle] builtInPlugInsPath] stringByAppendingPathComponent:@"Default.lunettesstyle"];
    NSBundle *defaultPlugin = [NSBundle bundleWithPath:pluginPath];
    NSAssert(defaultPlugin, @"Can't find the default path, this is bad");
    NSString *path = [defaultPlugin pathForResource:[self pageName] ofType:@"html"];
    return [NSURL fileURLWithPath:path];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
    self.isFrameLoaded = YES;      
    [self didFinishLoadForFrame:frame];
}

- (void)didFinishLoadForFrame:(WebFrame *)frame
{
    id win = [self windowScriptObject];
    NSWindow *window = [self window];
    [win setValue:self forKey:@"PlatformView"];
    [win setValue:[window windowController] forKey:@"PlatformWindowController"];
    [self setWindowTitle:[window title]];
    [self setViewedPlaying:_viewedPlaying];
    [self setViewedPosition:_viewedPosition];
    [self setCurrentTime:_currentTime];
}

#pragma mark -
#pragma mark Util

- (DOMHTMLElement *)htmlElementForId:(NSString *)idName;
{
    DOMElement *element = [[[self mainFrame] DOMDocument] getElementById:idName];
    NSAssert1([element isKindOfClass:[DOMHTMLElement class]], @"The '%@' element should be a DOMHTMLElement", idName);
    return (id)element;
}

#pragma mark -
#pragma mark Core -> Javascript setters

- (void)setWindowTitle:(NSString *)title
{
    if (_title != title) {
        [_title release];
        _title = [title copy];
    }
    if (!_isFrameLoaded)
        return;
    [self setInnerText:title forElementsOfClass:@"title"];
}

- (NSString *)windowTitle
{
    return _title;
}

- (void)setCurrentTime:(VLCTime *)time
{    
    if (_currentTime != time) {
        [_currentTime release];
        _currentTime = [time copy];
    }
    if (!_isFrameLoaded)
        return;
    [self setInnerText:[time stringValue] forElementsOfClass:@"ellapsed-time"];

    double currentTime = [[time numberValue] doubleValue];
    double position = [[self mediaPlayer] position];
    double remaining = currentTime / position * (1 - position);
    VLCTime *remainingTime = [VLCTime timeWithNumber:[NSNumber numberWithDouble:-remaining]];
    [self setInnerText:[remainingTime stringValue] forElementsOfClass:@"remaining-time"];
}

- (VLCTime *)currentTime
{
    return _currentTime;
}

// The viewedPosition value is set from the core to indicate a the position of the
// playing media.
// This is different from the setPosition: method that is being called by the
// javascript bridge (ie: from the interface code)
- (void)setViewedPosition:(float)position
{
    _viewedPosition = position;
    if (!_isFrameLoaded)
        return;
    [self setAttribute:@"value" value:[NSString stringWithFormat:@"%.0f", position * 1000] forElementsOfClass:@"timeline"];
}

- (float)viewedPosition
{
    return _viewedPosition;
}

- (void)setViewedPlaying:(BOOL)isPlaying
{
    _viewedPlaying = isPlaying;
    if (!_isFrameLoaded)
        return;
    if (isPlaying)
        [self addClassToContent:@"playing"];
    else
        [self removeClassFromContent:@"playing"];
}

- (BOOL)viewedPlaying
{
    return _viewedPlaying;
}

#pragma mark -
#pragma mark DOM manipulation

static NSString *escape(NSString *string)
{
    return [string stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
}

#define format(a, ...) [NSString stringWithFormat:[NSString stringWithUTF8String:a], __VA_ARGS__]
- (void)setInnerText:(NSString *)text forElementsOfClass:(NSString *)class
{
    id win = [self windowScriptObject];
    [win evaluateWebScript:format(
        "var elems = document.getElementsByClassName('%@'); \n"
        "for(var i = 0; i < elems.length; i++) \n"
        "   elems.item(i).innerText = '%@';",   escape(class), escape(text))
    ];
}

- (void)setAttribute:(NSString *)attribute value:(NSString *)value forElementsOfClass:(NSString *)class
{
    id win = [self windowScriptObject];
    [win evaluateWebScript:format(
        "var elems = document.getElementsByClassName('%@'); \n"
        "for(var i = 0; i < elems.length; i++) \n"
        "    elems.item(i).setAttribute('%@', '%@'); ",  escape(class), escape(attribute), escape(value))
    ];
}

- (void)addClassToContent:(NSString *)class
{
    if (!_isFrameLoaded)
        return;
    DOMHTMLElement *content = [self htmlElementForId:@"content"];
    NSString *currentClassName = content.className;
    
    if (!currentClassName)
        content.className = class;
    else if ([currentClassName rangeOfString:class].length == 0)
        content.className = [NSString stringWithFormat:@"%@ %@", content.className, class];
}

- (void)removeClassFromContent:(NSString *)class
{
    if (!_isFrameLoaded)
        return;
    DOMHTMLElement *content = [self htmlElementForId:@"content"];
    NSString *currentClassName = content.className;
    if (!currentClassName)
        return;
    NSRange range = [currentClassName rangeOfString:class];
    if (range.length > 0)
        content.className = [content.className stringByReplacingCharactersInRange:range withString:@""];
}

@end
