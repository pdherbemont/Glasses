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

- (void)dealloc
{
    VLCAssert(!_bindings, @"_bindings should have been released");
    VLCAssert(!_pathWatcher, @"Should not be here");
    [_resourcesFilePathArray release];
    [_lunettesStyleRoot release];
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
    [self setMaintainsBackForwardList:NO];

    [self setFrameLoadDelegate:self];
    [self setUIDelegate:self];
    //[self setEditingDelegate:self];
    [self setResourceLoadDelegate:self];

    NSURLRequest *request = [NSURLRequest requestWithURL:[self url] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:10];
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


- (NSString *)defaultPluginName
{
    NSString *pluginName = [[NSUserDefaults standardUserDefaults] stringForKey:kLastSelectedStyle];
    if (!pluginName)
        return @"Default";
    return pluginName;
}

- (void)setDefaultPluginName:(NSString *)pluginName
{
    VLCAssert(pluginName, @"We shouldn't set a null pluginName");
    [[NSUserDefaults standardUserDefaults] setObject:pluginName forKey:kLastSelectedStyle];
}

- (NSString *)pageName
{
    VLCAssertNotReached(@"You must override -pageName in your subclass");
    return nil;
}

- (NSURL *)urlForPluginName:(NSString *)pluginName
{
    VLCAssert(pluginName, @"pluginName shouldn't be null.");
    NSString *pluginFilename = [pluginName stringByAppendingPathExtension:@"lunettesstyle"];
    NSString *pluginPath = [[[NSBundle mainBundle] builtInPlugInsPath] stringByAppendingPathComponent:pluginFilename];
    VLCAssert(pluginPath, @"Can't find the plugin path, this is bad");
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

- (id)webView:(WebView *)sender identifierForInitialRequest:(NSURLRequest *)request fromDataSource:(WebDataSource *)dataSource
{
    return request;
}

- (NSCachedURLResponse *)webView:(WebView *)sender resource:(id)identifier willCacheResponse:(NSCachedURLResponse *)response fromDataSource:(WebDataSource *)dataSource
{
    // For some unknown reason, cache doesn't seem to properly work (ie, we're
    // probably getting some too soon expire http header.
    // We don't really care about those, so let's do our own caching.
    NSCachedURLResponse *cachedResponse;
    cachedResponse = [[[NSCachedURLResponse alloc] initWithResponse:[response response]
                                                               data:[response data]
                                                           userInfo:[response userInfo]
                                                      storagePolicy:NSURLCacheStorageAllowed] autorelease];

    [[NSURLCache sharedURLCache] storeCachedResponse:cachedResponse forRequest:identifier];
    return nil;
}


- (NSURLRequest *)webView:(WebView *)sender resource:(id)identifier willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse fromDataSource:(WebDataSource *)dataSource
{
    // Search for %lunettes_style_root%, and replace it by the root.

    NSString *filePathURL = [[[request URL] absoluteString] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSRange range = [filePathURL rangeOfString:@"%lunettes_style_root%"];
    BOOL isFileURL = [[request URL] isFileURL];
    if (range.location == NSNotFound) {
        if (watchForStyleModification() && isFileURL) {
            // FIXME - do we have any better?
            filePathURL = [filePathURL stringByReplacingOccurrencesOfString:@"file://" withString:@""];
            [_resourcesFilePathArray addObject:filePathURL];
        }
        if (!isFileURL) {
            // Check if we have it in cache.
            NSCachedURLResponse *cached = [[NSURLCache sharedURLCache] cachedResponseForRequest:request];
            if (cached && [[cached data] length] > 1000) {
                // Now, add the cached response to the WebResources. That will save
                // us from network access.
                if (![dataSource subresourceForURL:[request URL]]) {
                    WebResource *resource = [[WebResource alloc] initWithData:[cached data] URL:[request URL] MIMEType:[[cached response] MIMEType] textEncodingName:[[cached response] textEncodingName] frameName:[[dataSource webFrame] name]];
                    [dataSource addSubresource:resource];
                    [resource release];
                }
            }
        }
        return [NSURLRequest requestWithURL:[request URL] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:60];

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
    self.hasLoadedAFirstFrame = YES;

    if (watchForStyleModification()) {
        VLCAssert(!_pathWatcher, @"Shouldn't be created");
        _pathWatcher = [[VLCPathWatcher alloc] initWithFilePathArray:_resourcesFilePathArray];
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
        [_pathWatcher startWithBlock:^{
            NSLog(@"Reloading because of style change");
            [[self mainFrame] reload];
        }];
#else
        [_pathWatcher startWithDelegate:self];
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
    // We are coming out of a style change, let's fade in back
    if (![window alphaValue])
        [window setAlphaValue:1];
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


- (BOOL)webView:(WebView *)sender shouldPerformAction:(SEL)action fromSender:(id)fromObject
{
    if (action == @selector(selectAll:)) {
        [self selectAll:fromObject];
        return NO;
    }
    return NO;
}

- (void)selectAll:(id)sender
{

}

- (BOOL)webView:(WebView *)webView validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)item defaultValidation:(BOOL)defaultValidation
{
    return defaultValidation;
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)item
{
    return YES;
}

- (BOOL)webView:(WebView *)webView doCommandBySelector:(SEL)selector
{
    if (selector == @selector(selectAll:))
        [self selectAll:nil];
    return NO;
}

#pragma mark -
#pragma mark Path Watcher delegate

- (void)pathWatcherDidChange:(VLCPathWatcher *)pathWatcher
{
    NSLog(@"Reloading because style changed on file system");
    [[self mainFrame] reload];
}

#pragma mark -
#pragma mark Menu Item Action

- (void)setStyleFromMenuItem:(id)sender
{
    // We are going to change style, hide the window to prevent glitches.
    [[self window] setAlphaValue:0];

    // First, set the new style in our ivar, then reload using -setup.
    VLCAssert([sender isKindOfClass:[NSMenuItem class]], @"Only menu item are supported");
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
        VLCAssert([element isKindOfClass:[DOMHTMLElement class]], @"The '%@' element should be a DOMHTMLElement", idName);
    return (id)element;
}

- (DOMHTMLElement *)htmlElementForId:(NSString *)idName
{
    return [self htmlElementForId:idName canBeNil:NO];
}

#pragma mark -
#pragma mark Javascript

- (void)setSelectedIndexes:(WebScriptObject *)indexes inArrayController:(WebScriptObject *)target
{
    FROM_JS();
    NSArrayController *array = [target valueForKey:@"backendObject"];
    VLCAssert([array isKindOfClass:[NSArrayController class]], @"Must be a writable NSArrayController");

    NSMutableIndexSet *set = [NSMutableIndexSet indexSet];
    if (indexes && ![indexes isKindOfClass:[WebUndefined class]]) {
        id object = nil;
        for (size_t i = 0; (object = [indexes webScriptValueAtIndex:i]); i++) {
            if ([object isKindOfClass:[WebUndefined class]])
                break;
            [set addIndex:[object unsignedIntValue]];
        }
    }

    [array setSelectionIndexes:set];
    RETURN_NOTHING_TO_JS();
}

- (void)insertCocoaObject:(WebScriptObject *)object atIndex:(NSNumber *)index inArrayController:(WebScriptObject *)target
{
    FROM_JS();
    NSArrayController  *array = [target valueForKey:@"backendObject"];
    VLCAssert([array isKindOfClass:[NSArrayController class]], @"Must be a writable NSArrayController");
    [array insertObject:[object valueForKey:@"backendObject"] atArrangedObjectIndex:[index unsignedIntValue]];
    RETURN_NOTHING_TO_JS();
}

- (WebScriptObject *)createMediaFromURL:(NSString *)urlAsString inCocoaObject:(WebScriptObject *)object
{
    FROM_JS();
    VLCMedia *media = [VLCMedia mediaWithURL:[NSURL URLWithString:urlAsString]];
    RETURN_OBJECT_TO_JS([VLCWebBindingsController backendObject:media withWebScriptObject:object]);
}

- (void)bindDOMObject:(DOMNode *)domObject property:(NSString *)property toObject:(WebScriptObject *)object withKeyPath:(NSString *)keyPath options:(WebScriptObject *)options
{
    FROM_JS();
    NSMutableDictionary *opt = nil;
    if (options && ![options isKindOfClass:[WebUndefined class]]) {
        opt = [NSMutableDictionary dictionary];
        JSGlobalContextRef ctx = [[self mainFrame] globalContext];
        JSObjectRef object = [options JSObject];
        if (!object)
            return;
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
            else if ([name isEqualToString:@"NSValueTransformerNameBindingOption"])
                nameInNS = NSValueTransformerNameBindingOption;

            NSString *tempString = [NSString stringWithFormat:@"Unable to find the name for the option '%@'",name];
            VLCAssert(nameInNS, tempString);
            [opt setObject:[options valueForKey:name] forKey:nameInNS];
            [name release];
        }
        JSPropertyNameArrayRelease(props);
    }

    [_bindings bindDOMObject:domObject property:property toObject:object withKeyPath:keyPath options:opt];
    RETURN_NOTHING_TO_JS();
}

- (void)bindDOMObject:(DOMNode *)domObject property:(NSString *)property toBackendObject:(WebScriptObject *)object withKeyPath:(NSString *)keyPath options:(WebScriptObject *)options
{
    FROM_JS();
    [self bindDOMObject:domObject property:property toObject:[object valueForKey:@"backendObject"] withKeyPath:keyPath options:options];
    RETURN_NOTHING_TO_JS();
}

- (void)unbindDOMObject:(DOMNode *)domObject property:(NSString *)property
{
    FROM_JS();
    [_bindings unbindDOMObject:domObject property:property];
    RETURN_NOTHING_TO_JS();
}

- (void)addObserver:(WebScriptObject *)observer forCocoaObject:(WebScriptObject *)object withKeyPath:(NSString *)keyPath
{
    FROM_JS();
    [_bindings observe:[object valueForKey:@"backendObject"] withKeyPath:keyPath observer:observer];
    RETURN_NOTHING_TO_JS();
}

- (void)removeObserver:(WebScriptObject *)observer forCocoaObject:(WebScriptObject *)object withKeyPath:(NSString *)keyPath
{
    FROM_JS();
    [_bindings unobserve:[object valueForKey:@"backendObject"] withKeyPath:keyPath observer:observer];
    RETURN_NOTHING_TO_JS();
}


- (WebScriptObject *)createArrayControllerFromBackendObject:(WebScriptObject *)object withKeyPath:(NSString *)keyPath filterPredicateString:(NSString *)filterPredicateString
{
    FROM_JS();
    id backendObject = [object valueForKey:@"backendObject"];

    // Observing an NSArrayController arrangedObjects isn't great for
    // memory usage and does not work well. Try to simplify.
    NSArrayController *controller = nil;
    if ([keyPath hasSuffix:@".arrangedObjects"]) {
        id obj = [backendObject valueForKeyPath:[keyPath stringByDeletingPathExtension]];
        if ([obj isKindOfClass:[NSArrayController class]]) {
            if (filterPredicateString) {
                controller = [[NSArrayController alloc] init];
                [controller setContent:[obj content]];
            }
            else
                controller = [obj retain];
        }
    }
    if (!controller) {
        controller = [[NSArrayController alloc] init];
        [controller bind:@"content" toObject:backendObject withKeyPath:keyPath options:nil];
    }
    NSLog(@"predicate %@", filterPredicateString);
    if (filterPredicateString)
        [controller setFilterPredicate:[NSPredicate predicateWithFormat:filterPredicateString]];
    [controller setAutomaticallyRearrangesObjects:YES];
    [controller setEditable:YES];
    [controller setAutomaticallyPreparesContent:YES];
    WebScriptObject *ret = [object callWebScriptMethod:@"clone" withArguments:nil];
    ret = [VLCWebBindingsController backendObject:controller withWebScriptObject:ret];
    [controller release];
    RETURN_OBJECT_TO_JS(ret);
}

- (WebScriptObject *)viewBackendObject:(WebScriptObject *)object
{
    DIRECTLY_RETURN_OBJECT_TO_JS([VLCWebBindingsController backendObject:self withWebScriptObject:object]);
}

- (WebScriptObject *)documentBackendObject:(WebScriptObject *)object
{
    FROM_JS();
    NSDocument *doc = [[[self window] windowController] document];
    RETURN_OBJECT_TO_JS([VLCWebBindingsController backendObject:doc withWebScriptObject:object]);
}

- (void)willChangeObject:(WebScriptObject *)object valueForKey:(NSString *)key
{
    FROM_JS();
    [object willChangeValueForKey:key];
    RETURN_NOTHING_TO_JS();
}

- (void)didChangeObject:(WebScriptObject *)object valueForKey:(NSString *)key
{
    FROM_JS();
    [object didChangeValueForKey:key];
    RETURN_NOTHING_TO_JS();
}

- (void)setObject:(WebScriptObject *)object value:(id)value forKey:(NSString *)key
{
    FROM_JS();
    id backendObject = [object valueForKey:@"backendObject"];
    [backendObject setValue:value forKey:key];
    RETURN_NOTHING_TO_JS();
}

- (id)object:(WebScriptObject *)object valueForKey:(NSString *)key
{
    FROM_JS();
    id backendObject = [object valueForKey:@"backendObject"];
    RETURN_OBJECT_TO_JS([backendObject valueForKey:key]);
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)sel
{
    if (sel == @selector(removeObserver:forCocoaObject:withKeyPath:))
        return NO;
    if (sel == @selector(addObserver:forCocoaObject:withKeyPath:))
        return NO;
    if (sel == @selector(createMediaFromURL:inCocoaObject:))
        return NO;
    if (sel == @selector(setSelectedIndexes:inArrayController:))
        return NO;
    if (sel == @selector(insertCocoaObject:atIndex:inArrayController:))
        return NO;
    if (sel == @selector(bindDOMObject:property:toBackendObject:withKeyPath:options:))
        return NO;
    if (sel == @selector(bindDOMObject:property:toObject:withKeyPath:options:))
        return NO;
    if (sel == @selector(unbindDOMObject:property:))
        return NO;
    if (sel == @selector(createArrayControllerFromBackendObject:withKeyPath:filterPredicateString:))
        return NO;
    if (sel == @selector(documentBackendObject:))
        return NO;
    if (sel == @selector(viewBackendObject:))
        return NO;
    if (sel == @selector(willChangeObject:valueForKey:))
        return NO;
    if (sel == @selector(didChangeObject:valueForKey:))
        return NO;
    if (sel == @selector(setObject:value:forKey:))
        return NO;
    if (sel == @selector(object:valueForKey:))
        return NO;
    return YES;
}

+ (NSString *)webScriptNameForSelector:(SEL)sel
{
    if (sel == @selector(willChangeObject:valueForKey:))
        return @"willChange";
    if (sel == @selector(didChangeObject:valueForKey:))
        return @"didChange";
    if (sel == @selector(removeObserver:forCocoaObject:withKeyPath:))
        return @"removeObserverForCocoaObjectWithKeyPath";
    if (sel == @selector(addObserver:forCocoaObject:withKeyPath:))
        return @"addObserverForCocoaObjectWithKeyPath";
    if (sel == @selector(setSelectedIndexes:inArrayController:))
        return @"setSelectedIndexesInArrayController";
    if (sel == @selector(insertCocoaObject:atIndex:inArrayController:))
        return @"insertObjectAtIndexInArrayController";
    if (sel == @selector(createMediaFromURL:inCocoaObject:))
        return @"createMediaFromURL";
    if (sel == @selector(bindDOMObject:property:toBackendObject:withKeyPath:options:))
        return @"bindDOMObjectToCocoaObject";
    if (sel == @selector(bindDOMObject:property:toObject:withKeyPath:options:))
        return @"bindDOMObjectToObject";
    if (sel == @selector(unbindDOMObject:property:))
        return @"unbindDOMObject";
    if (sel == @selector(createArrayControllerFromBackendObject:withKeyPath:filterPredicateString:))
        return @"createArrayControllerFromBackendObjectWithKeyPathAndFilterPredicate";
    if (sel == @selector(viewBackendObject:))
        return @"viewBackendObject";
    if (sel == @selector(documentBackendObject:))
        return @"documentBackendObject";
    if (sel == @selector(setObject:value:forKey:))
        return @"setObjectValueForKey";
    if (sel == @selector(object:valueForKey:))
        return @"objectValueForKey";
    return nil;
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
    VLCAssert(_isFrameLoaded, @"Frame should be loaded");
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
