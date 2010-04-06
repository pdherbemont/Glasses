//
//  VLCSplashScreenView.h
//  Lunettes
//
//  Created by Pierre d'Herbemont on 2/1/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <WebKit/WebKit.h>
#import "VLCStyledView.h"

@interface VLCSplashScreenView : VLCStyledView {
    NSArrayController *_currentArrayController;
}

@property (readwrite, retain) NSArrayController *currentArrayController;

@end
