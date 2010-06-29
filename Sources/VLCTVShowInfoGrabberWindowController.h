//
//  VLCTVShowInfoGrabberWindowController.h
//  Lunettes
//
//  Created by Pierre d'Herbemont on 5/6/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class VLCTVShowInfoGrabber;

@interface VLCTVShowInfoGrabberWindowController : NSWindowController {
    NSString *_searchString;
    NSArray *_results;
    VLCTVShowInfoGrabber *_grabber;

    IBOutlet NSProgressIndicator *_progressIndicator;
}

@property (nonatomic, copy) NSString *searchString;
@property (readonly, retain) NSArray *results;

@end
