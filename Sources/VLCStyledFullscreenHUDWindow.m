//
//  VLCStyledFullscreenHUDWindow.m
//  Glasses
//
//  Created by Pierre d'Herbemont on 8/25/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "VLCStyledFullscreenHUDWindow.h"
#import "VLCStyledVideoWindow.h"
#import "VLCFullscreenController.h"

static inline BOOL debugStyledWindow(void)
{
    return [VLCStyledVideoWindow debugStyledWindow];
}

@implementation VLCStyledFullscreenHUDWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)style backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag;
{
    self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:bufferingType defer:flag];
    if (!self)
        return nil;
    [self setOpaque:NO];
    if (debugStyledWindow())
        [self setBackgroundColor:[NSColor colorWithCalibratedRed:1 green:0 blue:0 alpha:0.5]];
    else
        [self setBackgroundColor:[NSColor clearColor]];
    [self setAcceptsMouseMovedEvents:YES];
    [self setIgnoresMouseEvents:NO];
    [self setLevel:VLCFullscreenHUDWindowLevel];
    return self;
}

- (BOOL)canBecomeKeyWindow
{
    return YES;
}

- (BOOL)canBecomeMainWindow
{
    return YES;
}

@end
