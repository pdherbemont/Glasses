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
#import <JavaScriptCore/JavaScriptCore.h>

#import "VLCStyledView.h"
#import "VLCMediaDocument.h"
#import "VLCPathWatcher.h"
#import "VLCWebBindingsController.h"


@interface WebCoreStatistics : NSObject
+ (BOOL)shouldPrintExceptions;
+ (void)setShouldPrintExceptions:(BOOL)print;
@end

static BOOL watchForStyleModification(void)
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kWatchForStyleModification];
}

@interface VLCStyledView ()
@property (readwrite, assign) BOOL isFrameLoaded;
@property (readwrite, assign) NSString *pluginName;
- (void)setInnerText:(NSString *)text forElementsOfClass:(NSString *)class;
- (void)setAttribute:(NSString *)attribute value:(NSString *)value forElementsOfClass:(NSString *)class;
- (NSURL *)url;
@end

@implementation VLCStyledView
@synthesize isFrameLoaded=_isFrameLoaded;
@synthesize hasLoadedAFirstFrame=_hasLoadedAFirstFrame;
@synthesize pluginName=_pluginName;
@synthesize listCountString=_listCountString;

- (void)dealloc
{
    NSAssert(!_bindings, @"_bindings should have been released");
    NSAssert(!_pathWatcher, @"Should not be here");
    [_resourcesFilePathArray release];
    [_lunettesStyleRoot release];
    [_title release];
    [super dealloc];
}

- (void)setup
{
    self.isFrameLoaded = NO;

    [_bindings clearBindingsAndObservers];
    [_bindings release];
    _bindings = [[VLCWebBindingsController alloc] init];
    
    if (watchForStyleModification() && !_resourcesFilePathArray)
        _resourcesFilePathArray = [[NSMutableArray alloc] init];

    [WebCoreStatistics setShouldPrintExceptions:YES];
    [self setDrawsBackground:NO];

    [self setFrameLoadDelegate:self];
    [self setUIDelegate:self];
    [self setResourceLoadDelegate:self];

    NSURLRequest *request = [NSURLRequest requestWithURL:[self url]];
    [[self mainFrame] loadRequest:request];
}

- (void)close
{
    [_bindings clearBindingsAndObservers];
    [_bindings release];
    _bindings = nil;
    
    if (watchForStyleModification()) {
        [_pathWatcher stop];
        [_pathWatcher release];
        _pathWatcher = nil;        
    }
    self.isFrameLoaded = NO;
    [super close];
}

- (VLCMediaPlayer *)mediaPlayer
{
    return [[[[self window] windowController] document] mediaListPlayer].mediaPlayer;
}

- (NSString *)defaultPluginName
{
    NSString *pluginName = [[NSUserDefaults standardUserDefaults] stringForKey:kLastSelectedStyle];
    if (!pluginName)
        return @"Default";
    return pluginName;
}

- (void)setDefaultPluginName:(NSString *)pluginName
{
    NSAssert(pluginName, @"We shouldn't set a null pluginName");
    [[NSUserDefaults standardUserDefaults] setObject:pluginName forKey:kLastSelectedStyle];
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

- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame
{
    if (watchForStyleModification()) {
        [_pathWatcher stop];
        [_pathWatcher release];
        _pathWatcher = nil;
        if (!_resourcesFilePathArray)
            _resourcesFilePathArray = [[NSMutableArray alloc] init];
        else
            [_resourcesFilePathArray removeAllObjects];
    }
}

- (NSURLRequest *)webView:(WebView *)sender resource:(id)identifier willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse fromDataSource:(WebDataSource *)dataSource
{
    // Search for %lunettes_style_root%, and replace it by the root.
    
    NSString *filePathURL = [[[request URL] absoluteString] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSRange range = [filePathURL rangeOfString:@"%lunettes_style_root%"];
    if (range.location == NSNotFound) {
        if (watchForStyleModification()) {
            // FIXME - do we have any better?
            filePathURL = [filePathURL stringByReplacingOccurrencesOfString:@"file://" withString:@""];
            [_resourcesFilePathArray addObject:filePathURL];
        }
        return request;
        
    }
    
    NSString *resource = [filePathURL substringFromIndex:range.location + range.length];
    if (!_lunettesStyleRoot)
        _lunettesStyleRoot = [[[NSBundle mainBundle] pathForResource:@"Lunettes Style Root" ofType:nil] retain];
    
    NSString *newFilePathURL = [_lunettesStyleRoot stringByAppendingString:resource];
    
    if (watchForStyleModification())
        [_resourcesFilePathArray addObject:newFilePathURL];
    
    NSURL *url = [NSURL fileURLWithPath:newFilePathURL];
    return [NSURLRequest requestWithURL:url];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
    self.isFrameLoaded = YES;      
    [self didFinishLoadForFrame:frame];

    // Tell our Document that we are now ready and initialized.
    // This is to make sure that we play only once the webview is loaded.
    // This way we wont overload the CPU, during opening.
    if (!self.hasLoadedAFirstFrame) {
        NSWindowController *controller = [[self window] windowController];
        [[controller document] didFinishLoadingWindowController:controller];
    }
    
    self.hasLoadedAFirstFrame = YES;

    if (watchForStyleModification()) {
        NSAssert(!_pathWatcher, @"Shouldn't be created");
        _pathWatcher = [[VLCPathWatcher alloc] initWithFilePathArray:_resourcesFilePathArray];
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
        [_pathWatcher startWithBlock:^{
            NSLog(@"Reloading because of style change");
            [[self mainFrame] reload];
        }];
#else
        [_pathWatcher startWithMainFrame:[self mainFrame]];
        [[self mainFrame]reload];
#endif
    }
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
    [self setSeekable:_seekable];
    [self setListCount:_listCount];
    [self setSublistCount:_sublistCount];

    // We are coming out of a style change, let's fade in back
    if (![window alphaValue])
        [[[self window] animator] setAlphaValue:1];
}

- (NSUInteger)webView:(WebView *)sender dragDestinationActionMaskForDraggingInfo:(id <NSDraggingInfo>)draggingInfo
{
    // Only allow javascript to handle drop.
    return WebDragDestinationActionDHTML;
}

- (NSUInteger)webView:(WebView *)sender dragSourceActionMaskForPoint:(NSPoint)point
{
    // Only allow javascript to handle drag.
    return WebDragSourceActionDHTML;
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
#pragma mark Remote Control events

- (void)sendRemoteButtonEvent:(NSString *)name selector:(SEL)sel
{
    id ret = [[[self mainFrame] windowObject] callWebScriptMethod:@"remoteButtonHandler" withArguments:[NSArray arrayWithObject:name]];
    if ([ret isKindOfClass:[NSNumber class]] && [ret boolValue])
        return; // Event was handled with success.

    // try to emulate what [NSApp sendAction:] does, ie reach NSDocument.
    BOOL success = [[self nextResponder] tryToPerform:sel with:nil];
    if (!success) {
        id document = [[[self window] windowController] document];
        if ([document respondsToSelector:sel]) {
            [document performSelector:sel withObject:nil];
            success = YES;
        }
    }
    if (!success)
        NSBeep();
}

- (void)remoteMiddleButtonPressed:(id)sender
{
    [self sendRemoteButtonEvent:@"middle" selector:_cmd];
}

- (void)remoteMenuButtonPressed:(id)sender
{
    [self sendRemoteButtonEvent:@"menu" selector:_cmd];
}

- (void)remoteUpButtonPressed:(id)sender
{
    [self sendRemoteButtonEvent:@"up" selector:_cmd];
}

- (void)remoteDownButtonPressed:(id)sender
{
    [self sendRemoteButtonEvent:@"down" selector:_cmd];
}

- (void)remoteRightButtonPressed:(id)sender
{
    [self sendRemoteButtonEvent:@"right" selector:_cmd];
}

- (void)remoteLeftButtonPressed:(id)sender
{
    [self sendRemoteButtonEvent:@"left" selector:_cmd];
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
#pragma mark Javascript

- (void)setPosition:(float)position
{
    [[self mediaPlayer] setPosition:position];
    [[[[self window] windowController] document] playbackPositionChanged];
}

- (void)play
{    
    [[self mediaPlayer] play];
}

- (void)pause
{
    [[self mediaPlayer] pause];
}

- (BOOL)isSeekable
{
    return [[self mediaPlayer] isSeekable];
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

- (NSUInteger)count
{
    return [[self rootMediaList] count];
}

- (void)bindDOMObject:(DOMNode *)domObject property:(NSString *)property toObject:(WebScriptObject *)object withKeyPath:(NSString *)keyPath options:(WebScriptObject *)options
{
    NSMutableDictionary *opt = nil;
    if (![options isKindOfClass:[WebUndefined class]]) {
        opt = [NSMutableDictionary dictionary];
        JSGlobalContextRef ctx = [[self mainFrame] globalContext];
        JSObjectRef object = [options JSObject];
        JSPropertyNameArrayRef props = JSObjectCopyPropertyNames(ctx, object);
        size_t count = JSPropertyNameArrayGetCount(props);
        for (size_t i = 0; i < count; i++) {
            JSStringRef nameAsJS = JSPropertyNameArrayGetNameAtIndex(props, i);
            NSString *name = NSMakeCollectable(JSStringCopyCFString(NULL, nameAsJS));
            NSString *nameInNS = nil;

            if ([name isEqualToString:@"NSPredicateFormatBindingOption"])
                nameInNS = NSPredicateFormatBindingOption;
            else if ([name isEqualToString:@"NSNullPlaceholderBindingOption"])
                nameInNS = NSNullPlaceholderBindingOption;

            NSString *tempString = [NSString stringWithFormat:@"Unable to find the name for the option '%@'",name];
            NSAssert(nameInNS, tempString);
            [opt setObject:[options valueForKey:name] forKey:nameInNS];
            [name release];
        }
        JSPropertyNameArrayRelease(props);
    }

    [_bindings bindDOMObject:domObject property:property toObject:object withKeyPath:keyPath options:opt];
}

- (void)bindDOMObject:(DOMNode *)domObject property:(NSString *)property toBackendObject:(WebScriptObject *)object withKeyPath:(NSString *)keyPath options:(WebScriptObject *)options
{
    [self bindDOMObject:domObject property:property toObject:[object valueForKey:@"backendObject"] withKeyPath:keyPath options:options];
}

- (void)unbindDOMObject:(DOMNode *)domObject property:(NSString *)property
{
    [_bindings unbindDOMObject:domObject property:property];
}

- (void)addObserver:(WebScriptObject *)observer forCocoaObject:(WebScriptObject *)object withKeyPath:(NSString *)keyPath
{
    [_bindings observe:[object valueForKey:@"backendObject"] withKeyPath:keyPath observer:observer];
}

- (void)playCocoaObject:(WebScriptObject *)object
{
    [[self mediaListPlayer] playMedia:[object valueForKey:@"backendObject"]];
}

- (WebScriptObject *)createArrayControllerFromBackendObject:(WebScriptObject *)object withKeyPath:(NSString *)keyPath
{
    id backendObject = [object valueForKey:@"backendObject"];
    NSArrayController *controller = [[NSArrayController alloc] init];
    [controller setAutomaticallyRearrangesObjects:YES];
    [controller bind:@"contentArray" toObject:backendObject withKeyPath:keyPath options:nil];
    WebScriptObject *ret = [object callWebScriptMethod:@"clone" withArguments:nil];
    [ret setValue:controller forKey:@"backendObject"];
    [controller release];
    return ret;
}

- (WebScriptObject *)viewBackendObject:(WebScriptObject *)object
{
    [object setValue:self forKey:@"backendObject"];
    return object;
}

- (void)willChangeObject:(WebScriptObject *)object valueForKey:(NSString *)key
{
    [object willChangeValueForKey:key];
}

- (void)didChangeObject:(WebScriptObject *)object valueForKey:(NSString *)key
{
    [object didChangeValueForKey:key];
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)sel
{
    if (sel == @selector(count))
        return NO;
    if (sel == @selector(play))
        return NO;
    if (sel == @selector(pause))
        return NO;
    if (sel == @selector(setPosition:))
        return NO;
    if (sel == @selector(isSeekable))
        return NO;
    if (sel == @selector(addObserver:forCocoaObject:withKeyPath:))
        return NO;
    if (sel == @selector(bindDOMObject:property:toBackendObject:withKeyPath:options:))
        return NO;   
    if (sel == @selector(bindDOMObject:property:toObject:withKeyPath:options:))
        return NO;   
    if (sel == @selector(unbindDOMObject:property:))
        return NO;
    if (sel == @selector(playCocoaObject:))
        return NO;   
    if (sel == @selector(createArrayControllerFromBackendObject:withKeyPath:))
        return NO;   
    if (sel == @selector(viewBackendObject:))
        return NO;   
    if (sel == @selector(willChangeObject:valueForKey:))
        return NO;   
    if (sel == @selector(didChangeObject:valueForKey:))
        return NO;   
    return YES;
}

+ (NSString *)webScriptNameForSelector:(SEL)sel
{
    if (sel == @selector(willChangeObject:valueForKey:))
        return @"willChange";
    if (sel == @selector(didChangeObject:valueForKey:))
        return @"didChange";
    if (sel == @selector(addObserver:forCocoaObject:withKeyPath:))
        return @"addObserverForCocoaObjectWithKeyPath";
    if (sel == @selector(bindDOMObject:property:toBackendObject:withKeyPath:options:))
        return @"bindDOMObjectToCocoaObject";
    if (sel == @selector(bindDOMObject:property:toObject:withKeyPath:options:))
        return @"bindDOMObjectToObject";
    if (sel == @selector(unbindDOMObject:property:))
        return @"unbindDOMObject";
    if (sel == @selector(playCocoaObject:))
        return @"playCocoaObject";
    if (sel == @selector(createArrayControllerFromBackendObject:withKeyPath:))
        return @"createArrayControllerFromBackendObjectWithKeyPath";
    if (sel == @selector(viewBackendObject:))
        return @"viewBackendObject";
    return nil;
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
    
    [self setListCountString:[NSString stringWithFormat:@"%d item%s", count, count > 1 ? "s" : ""]];
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

- (void)setShowPlaylist:(BOOL)show
{
    _showPlaylist = show;
}

- (BOOL)showPlaylist
{
    return _showPlaylist;
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

- (BOOL)contentHasClassName:(NSString *)class
{
    NSAssert(_isFrameLoaded, @"Frame should be loaded");
    DOMHTMLElement *content = [self htmlElementForId:@"content"];
    NSString *currentClassName = content.className;
    return [currentClassName rangeOfString:class].length > 0;
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
