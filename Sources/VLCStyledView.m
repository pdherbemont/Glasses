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


@interface WebCoreStatistics : NSObject
+ (BOOL)shouldPrintExceptions;
+ (void)setShouldPrintExceptions:(BOOL)print;
@end

static NSString *defaultPluginNamePreferencesKey = @"LastSelectedStyle";

@interface VLCStyledView ()
@property (readwrite, assign) BOOL isFrameLoaded;
@property (readwrite, assign) NSString *pluginName;
- (void)setInnerText:(NSString *)text forElementsOfClass:(NSString *)class;
- (void)setAttribute:(NSString *)attribute value:(NSString *)value forElementsOfClass:(NSString *)class;
- (NSURL *)url;
@end

@implementation VLCStyledView
@synthesize isFrameLoaded=_isFrameLoaded;
@synthesize pluginName=_pluginName;

- (void)dealloc
{
    [_title release];
    [_currentTime release];
    [super dealloc];
}

- (void)setup
{
    [WebCoreStatistics setShouldPrintExceptions:YES];
    [self setDrawsBackground:NO];
    
    [self setFrameLoadDelegate:self];
    [self setUIDelegate:self];
    [self setResourceLoadDelegate:self];
    NSURL *url = [self url];
    NSString *rawContent = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
    NSURL *lunettesstyleRoot = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Lunettes Style Root" ofType:nil]];
    NSString *content = [rawContent stringByReplacingOccurrencesOfString:@"%lunettes_style_root%" withString:[lunettesstyleRoot absoluteString]];
    [[self mainFrame] loadHTMLString:content baseURL:url];
}

- (VLCMediaPlayer *)mediaPlayer
{
    return [[[[self window] windowController] document] mediaListPlayer].mediaPlayer;
}

- (NSString *)defaultPluginName
{
    NSString *pluginName = [[NSUserDefaults standardUserDefaults] stringForKey:defaultPluginNamePreferencesKey];
    if (!pluginName)
        return @"Default";
    return pluginName;
}

- (void)setDefaultPluginName:(NSString *)pluginName
{
    NSAssert(pluginName, @"We shouldn't set a null pluginName");
    [[NSUserDefaults standardUserDefaults] setObject:pluginName forKey:defaultPluginNamePreferencesKey];
}

- (NSString *)pageName
{
    VLCAssertNotReached(@"You must override -pageName in your subclass");
    return nil;
}

- (NSURL *)urlForPluginName:(NSString *)pluginName
{
    NSAssert(pluginName, @"pluginName shouldn't be null.");
    NSString *pluginFilename = [pluginName stringByAppendingPathExtension:@"lunettesstyle"];
    NSString *pluginPath = [[[NSBundle mainBundle] builtInPlugInsPath] stringByAppendingPathComponent:pluginFilename];
    NSAssert(pluginPath, @"Can't find the plugin path, this is bad");
    NSBundle *plugin = [NSBundle bundleWithPath:pluginPath];
    if (!plugin)
        return nil;
    NSString *path = [plugin pathForResource:[self pageName] ofType:@"html"];
    if (!path)
        return nil;
    return [NSURL fileURLWithPath:path];
}

- (NSURL *)url
{
    NSString *pluginName = [self pluginName];
    if (!pluginName)
        pluginName = [self defaultPluginName];
    NSURL *filePath = [self urlForPluginName:pluginName];
    // Nothing found, fallback to the default plugin.
    // This allows to reimplement just the window
    // or just the HUD.
    if (!filePath)
        filePath = [self urlForPluginName:@"Default"];
    return filePath;
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
    self.isFrameLoaded = YES;      
    [self didFinishLoadForFrame:frame];
}

- (void)webView:(WebView *)webView windowScriptObjectAvailable:(WebScriptObject *)windowScriptObject
{
    [windowScriptObject setValue:self forKey:@"PlatformView"];
    [windowScriptObject setValue:[[self window] windowController] forKey:@"PlatformWindowController"];
}

- (void)didFinishLoadForFrame:(WebFrame *)frame
{
    NSWindow *window = [self window];
    [self setWindowTitle:[window title]];
    [self setViewedPlaying:_viewedPlaying];
    [self setViewedPosition:_viewedPosition];
    [self setSeekable:_seekable];
    [self setCurrentTime:_currentTime];
    [self setListCount:_listCount];
    [self setSublistCount:_sublistCount];

    // We are coming out of a style change, let's fade in back
    if (![window alphaValue])
        [[[self window] animator] setAlphaValue:1];
}

#pragma mark -
#pragma mark Menu Item Action

- (void)setStyleFromMenuItem:(id)sender
{
    // We are going to change style, hide the window to prevent glitches.
    [[self window] setAlphaValue:0];

    // First, set the new style in our ivar, then reload using -setup.
    NSAssert([sender isKindOfClass:[NSMenuItem class]], @"Only menu item are supported");
    NSMenuItem *item = sender;
    self.pluginName = [item title];
    [self setDefaultPluginName:self.pluginName];
    [self setup];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    SEL sel = [menuItem action];
    if (sel != @selector(setStyleFromMenuItem:))
        return NO;
    NSString *pluginName = self.pluginName;
    if (!pluginName)
        pluginName = [self defaultPluginName];
    BOOL isCurrentPlugin = [[menuItem title] isEqualToString:pluginName];
    [menuItem setState:isCurrentPlugin ? NSOnState : NSOffState];
    return YES;
}

#pragma mark -
#pragma mark Util

- (DOMHTMLElement *)htmlElementForId:(NSString *)idName canBeNil:(BOOL)canBeNil
{
    DOMElement *element = [[[self mainFrame] DOMDocument] getElementById:idName];
    if (!canBeNil)
        NSAssert1([element isKindOfClass:[DOMHTMLElement class]], @"The '%@' element should be a DOMHTMLElement", idName);
    return (id)element;
}

- (DOMHTMLElement *)htmlElementForId:(NSString *)idName
{
    return [self htmlElementForId:idName canBeNil:NO];
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

    NSNumber *timeAsNumber = [time numberValue];
    VLCTime *remainingTime;
    if (!timeAsNumber) {
        // There is no time as number,
        // it means we have no time,
        // just display "--:--"
        remainingTime = [VLCTime nullTime];
    }
    else {
        double currentTime = [[time numberValue] doubleValue];
        double position = [[self mediaPlayer] position];
        double remaining = currentTime / position * (1 - position);
        remainingTime = [VLCTime timeWithNumber:[NSNumber numberWithDouble:-remaining]];        
    }
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

- (void)setSeekable:(BOOL)isSeekable
{
    _seekable = isSeekable;
    if (!_isFrameLoaded)
        return;
    if (isSeekable)
        [self addClassToContent:@"seekable"];
    else
        [self removeClassFromContent:@"seekable"];    
    
}

- (BOOL)seekable
{
    return _seekable;
}

- (void)setHTMLListCount:(NSUInteger)count
{
    DOMHTMLElement *element = [self htmlElementForId:@"items-count" canBeNil:YES];
    [element setInnerText:[NSString stringWithFormat:@"%d", count]];
    
    if (count == 1)
        [self removeClassFromContent:@"multiple-play-items"];
    else
        [self addClassToContent:@"multiple-play-items"];
}

- (void)setListCount:(NSUInteger)count
{
    _listCount = count;
    
    // Use the sublist count if we have subitems.
    if (_sublistCount > 0)
        return;
    
    [self setHTMLListCount:count];
}

- (NSUInteger)listCount
{
    return _listCount;
}

- (void)setSublistCount:(NSUInteger)count
{
    _sublistCount = count;
    
    // No subitems, use the list count.
    if (_sublistCount == 0)
        return;
    
    [self setHTMLListCount:count];
}

- (NSUInteger)sublistCount
{
    return _sublistCount;
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
