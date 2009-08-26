//
//  VLCStyledFullscreenHUDWindowViewController.m
//  Glasses
//
//  Created by Pierre d'Herbemont on 8/25/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "VLCStyledFullscreenHUDWindowController.h"


@implementation VLCStyledFullscreenHUDWindowController

- (NSString *)windowNibName
{
	return @"StyledFullscreenHUDWindow";
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    NSLog(@"DidLoad");
    NSAssert(_styledWindowView, @"_styledWindowView is not properly set in Nib file");
    [_styledWindowView bind:@"currentTime" toObject:self withKeyPath:@"document.mediaListPlayer.mediaPlayer.time" options:nil];
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:0], NSNullPlaceholderBindingOption, nil];
    [_styledWindowView bind:@"viewedPosition" toObject:self withKeyPath:@"document.mediaListPlayer.mediaPlayer.position" options:options];
    options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSNullPlaceholderBindingOption, nil];
    [_styledWindowView bind:@"viewedPlaying" toObject:self withKeyPath:@"document.mediaListPlayer.mediaPlayer.playing" options:options];
}

#pragma mark -
#pragma mark VLCFullscreenHUD protocol

- (void)fullscreenController:(VLCFullscreenController *)controller didEnterFullscreen:(NSScreen *)screen
{
    _fullscreenController = controller;
    NSWindow *window = [self window];
    NSAssert(window, @"There is no window associated to this windowController. Check the .xib files.");
    [window setFrame:[screen frame] display:NO];
    [window makeKeyAndOrderFront:self];
}

- (void)fullscreenControllerWillLeaveFullscreen:(VLCFullscreenController *)controller
{
    [[self window] orderOut:self];
}

#pragma mark -
#pragma mark Javascript brigding

- (void)leaveFullscreen
{
    [_fullscreenController leaveFullscreen];
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)sel;
{
    if (sel == @selector(leaveFullscreen))
        return NO;    
    return YES;
}

+ (BOOL)isKeyExcludedFromWebScript:(const char *)name
{
    return YES;
}
@end
