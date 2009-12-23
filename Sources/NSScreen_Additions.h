//
//  NSScreen_Additions.h
//  Lunettes
//
//  Created by Pierre d'Herbemont on 4/11/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSScreen (VLCAdditions)
+ (NSScreen *)screenWithDisplayID:(CGDirectDisplayID)displayID;
- (BOOL)isMainScreen;
- (BOOL)isScreen:(NSScreen *)screen;
- (CGDirectDisplayID)displayID;
@end
