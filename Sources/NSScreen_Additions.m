//
//  NSScreen_Additions.m
//  VLC light
//
//  Created by Pierre d'Herbemont on 4/11/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NSScreen_Additions.h"


@implementation NSScreen (VLCAdditions)

+ (NSScreen *)screenWithDisplayID: (CGDirectDisplayID)displayID
{
    int i;
	
    for( i = 0; i < [[NSScreen screens] count]; i++ )
    {
        NSScreen *screen = [[NSScreen screens] objectAtIndex: i];
        if([screen displayID] == displayID)
            return screen;
    }
    return nil;
}

- (BOOL)isMainScreen
{
    return ([self displayID] == [[[NSScreen screens] objectAtIndex:0] displayID]);
}

- (BOOL)isScreen: (NSScreen*)screen
{
    return ([self displayID] == [screen displayID]);
}

- (CGDirectDisplayID)displayID
{
    return (CGDirectDisplayID)_screenNumber;
}

@end
