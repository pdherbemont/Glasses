//
//  NSScreen_Additions.m
//  Lunettes
//
//  Created by Pierre d'Herbemont on 4/11/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NSScreen_Additions.h"


@implementation NSScreen (VLCAdditions)

+ (NSScreen *)screenWithDisplayID:(CGDirectDisplayID)displayID
{
    unsigned i;
    NSArray *screens = [NSScreen screens];
    for (i = 0; i < [screens count]; i++) {
        NSScreen *screen = [screens objectAtIndex:i];
        if ([screen displayID] == displayID)
            return screen;
    }
    return nil;
}

- (BOOL)isMainScreen
{
    return [self displayID] == [[[NSScreen screens] objectAtIndex:0] displayID];
}

- (BOOL)isScreen:(NSScreen *)screen
{
    return [self displayID] == [screen displayID];
}

- (CGDirectDisplayID)displayID
{
    return (CGDirectDisplayID)[[[self deviceDescription]objectForKey:@"NSScreenNumber"]intValue];
}

@end
