//
//  VLCStyledFullscreenHUDWindowViewController.h
//  Glasses
//
//  Created by Pierre d'Herbemont on 8/25/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VLCFullscreenController.h"

@class VLCStyledFullscreenHUDWindowView;
@interface VLCStyledFullscreenHUDWindowController : NSWindowController <VLCFullscreenHUD>
{
    IBOutlet VLCStyledFullscreenHUDWindowView *_styledWindowView;

    VLCFullscreenController *_fullscreenController; // Weak
}
@end
