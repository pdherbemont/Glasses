//
//  VLCSplashScreenWindowController.h
//  Lunettes
//
//  Created by Pierre d'Herbemont on 8/27/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface VLCSplashScreenWindowController : NSWindowController {
    BOOL _releasedWhenClosed;
}

@property BOOL releasedWhenClosed;

- (IBAction)reportBug:(id)sender;
@end
