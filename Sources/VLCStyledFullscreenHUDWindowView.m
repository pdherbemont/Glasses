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

#import "VLCStyledFullscreenHUDWindowView.h"

#import "VLCMediaDocument.h"

@implementation VLCStyledFullscreenHUDWindowView

- (void) dealloc
{
    NSAssert(!_bindings, @"_bindings should have been released");
    [super dealloc];
}

- (void)close
{
    [_bindings clearBindingsAndObservers];
    [_bindings release];
    _bindings = nil;
    [super close];
}

- (void)setup
{
    [_bindings clearBindingsAndObservers];
    [_bindings release];
    _bindings = [[VLCWebBindingsController alloc] init];
    [super setup];
}

- (void)awakeFromNib
{
    [self setup];    
}

- (NSString *)pageName
{
    return @"hud";
}

- (void)didFinishLoadForFrame:(WebFrame *)frame
{
    [super didFinishLoadForFrame:frame];

    // Make sure the cursor is hidden, at this point the js is
    // ready to handle the cursor visibility.
    [NSCursor setHiddenUntilMouseMoves:YES];
}

- (void)cancelOperation:(id)sender
{
    [[[self window] windowController] leaveFullscreen];
}

- (void)mouseDown:(NSEvent *)event
{
	if ([event clickCount] == 2)
		[[[self window] windowController] leaveFullscreen];
    else
        [super mouseDown:event];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event
{
    return YES;
}

- (void)keyDown:(NSEvent *)theEvent
{

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

- (void)hideCursorUntilMouseMoves
{
    [NSCursor setHiddenUntilMouseMoves:YES];
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

- (void)playMediaAtIndex:(NSUInteger)index
{
    [[self mediaListPlayer] playMedia:[[self rootMediaList] mediaAtIndex:index]];
}

- (NSString *)titleAtIndex:(NSUInteger)index
{
    return [[[self rootMediaList] mediaAtIndex:index].metaDictionary objectForKey:@"title"];
}

- (NSUInteger)count
{
    return [[self rootMediaList] count];
}

- (void)bindDOMObject:(DOMObject *)domObject property:(NSString *)property toKeyPath:(NSString *)keyPath
{
    NSAssert(_bindings, @"No bindings created");
    [_bindings bindDOMObject:domObject property:property toObject:self withKeyPath:keyPath];
}

- (void)bindDOMObject:(DOMNode *)domObject property:(NSString *)property toBackendObject:(WebScriptObject*)object withKeyPath:(NSString *)keyPath
{
    NSAssert(_bindings, @"No bindings created");
    [_bindings bindDOMObject:domObject property:property toObject:[object valueForKey:@"backendObject"] withKeyPath:keyPath];
}

- (void)unbindDOMObject:(DOMNode *)domObject property:(NSString *)property
{
    NSAssert(_bindings, @"No bindings created");
    [_bindings unbindDOMObject:domObject property:property];
}

- (void)addObserver:(WebScriptObject *)observer forCocoaObject:(WebScriptObject *)object withKeyPath:(NSString *)keyPath
{
    NSAssert(_bindings, @"No bindings created");
    [_bindings observe:object ? [object valueForKey:@"backendObject"] : self withKeyPath:keyPath observer:observer];
}

- (void)playCocoaObject:(WebScriptObject *)object
{
    [[self mediaListPlayer] playMedia:[object valueForKey:@"backendObject"]];
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)sel
{
    if (sel == @selector(playMediaAtIndex:))
        return NO;
    if (sel == @selector(titleAtIndex:))
        return NO;
    if (sel == @selector(count))
        return NO;    
    if (sel == @selector(play))
        return NO;
    if (sel == @selector(pause))
        return NO;
    if (sel == @selector(setPosition:))
        return NO;
    if (sel == @selector(hideCursorUntilMouseMoves))
        return NO;
    if (sel == @selector(bindDOMObject:property:toKeyPath:))
        return NO;    
    if (sel == @selector(addObserver:forCocoaObject:withKeyPath:))
        return NO;
    if (sel == @selector(bindDOMObject:property:toBackendObject:withKeyPath:))
        return NO;
    if (sel == @selector(unbindDOMObject:property:))
        return NO;
    if (sel == @selector(playCocoaObject:))
        return NO;       
    return YES;
}

+ (NSString *)webScriptNameForSelector:(SEL)sel
{
    if (sel == @selector(bindDOMObject:property:toKeyPath:))
        return @"bindPropertyTo";
    if (sel == @selector(addObserver:forCocoaObject:withKeyPath:))
        return @"addObserverForCocoaObjectWithKeyPath";
    if (sel == @selector(bindDOMObject:property:toBackendObject:withKeyPath:))
        return @"bindDOMObjectToCocoaObject";
    if (sel == @selector(unbindDOMObject:property:))
        return @"unbindDOMObject";
    if (sel == @selector(playCocoaObject:))
        return @"playCocoaObject";
    return nil;
}

+ (BOOL)isKeyExcludedFromWebScript:(const char *)name
{
    return YES;
}

@end
