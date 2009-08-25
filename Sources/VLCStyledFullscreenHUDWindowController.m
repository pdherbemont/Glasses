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

#pragma mark -
#pragma mark VLCFullscreenHUD protocol
- (void)fullscreenController:(VLCFullscreenController *)controller didEnterFullscreen:(NSScreen *)screen
{
    NSWindow *window = [self window];
    NSAssert(window, @"There is no window associated to this windowController. Check the .xib files.");
    [window setFrame:[screen frame] display:NO];
    [window makeKeyAndOrderFront:self];
}

- (void)fullscreenControllerWillLeaveFullscreen:(VLCFullscreenController *)controller
{
    [[self window] close];
}
@end
