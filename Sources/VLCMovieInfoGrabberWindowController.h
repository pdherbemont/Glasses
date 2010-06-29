//
//  VLCMovieInfoGrabberWindowController.h
//  Lunettes
//
//  Created by Pierre d'Herbemont on 5/5/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class VLCMovieInfoGrabber;

@interface VLCMovieInfoGrabberWindowController : NSWindowController {
    NSString *_searchString;
    NSArray *_results;
    VLCMovieInfoGrabber *_grabber;

    IBOutlet NSProgressIndicator *_progressIndicator;
    IBOutlet NSArrayController *_resultsArrayController;
}

@property (nonatomic, copy) NSString *searchString;
@property (readonly, retain) NSArray *results;

- (IBAction)applyToSelectedMedia:(id)sender;
@end
