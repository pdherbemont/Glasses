//
//  VLCStyledFullscreenHUDWindowView.m
//  Glasses
//
//  Created by Pierre d'Herbemont on 8/25/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <VLCKit/VLCKit.h>

#import "VLCStyledFullscreenHUDWindowView.h"

#import "VLCMediaDocument.h"

@implementation VLCStyledFullscreenHUDWindowView

- (void)awakeFromNib
{
    [self setup];    
}

- (NSURL *)url
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"hud" ofType:@"html"];
    return [NSURL fileURLWithPath:path];
}

- (void)didFinishLoadForFrame:(WebFrame *)frame
{
    [super didFinishLoadForFrame:frame];
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

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)sel;
{
    if (sel == @selector(play))
        return NO;
    if (sel == @selector(pause))
        return NO;
    if (sel == @selector(setPosition:))
        return NO;
    if (sel == @selector(hideCursorUntilMouseMoves))
        return NO;
    return YES;
}

+ (BOOL)isKeyExcludedFromWebScript:(const char *)name
{
    return YES;
}

@end
