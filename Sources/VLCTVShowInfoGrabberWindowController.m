//
//  VLCTVShowInfoGrabberWindowController.m
//  Lunettes
//
//  Created by Pierre d'Herbemont on 5/6/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "VLCTVShowInfoGrabberWindowController.h"
#import "VLCTVShowInfoGrabber.h"

@interface VLCTVShowInfoGrabberWindowController () <VLCTVShowInfoGrabberDelegate>
@property (readwrite, retain) NSArray *results;
@end


@implementation VLCTVShowInfoGrabberWindowController
@synthesize searchString=_searchString;
@synthesize results=_results;

- (void)dealloc
{
    [_searchString release];
    [_results release];
    [_grabber release];
    [super dealloc];
}

- (NSString *)windowNibName
{
    return @"TVShowInfoGrabberWindow";
}

- (void)setSearchString:(NSString *)string
{
    [_searchString release];
    _searchString = [string copy];
    if (!string) {
        self.results = [NSMutableArray array];
        return;
    }
    [_progressIndicator startAnimation:nil];

    if (!_grabber) {
        _grabber = [[VLCTVShowInfoGrabber alloc] init];
        [_grabber setDelegate:self];
    }
    [_grabber lookUpForTitle:string];

    // We are now waiting for delegate methods
}

- (void)tvShowInfoGrabber:(VLCTVShowInfoGrabber *)grabber didFailWithError:(NSError *)error
{
    [_progressIndicator stopAnimation:nil];
}

- (void)tvShowInfoGrabberDidFinishGrabbing:(VLCTVShowInfoGrabber *)grabber
{
    [_progressIndicator stopAnimation:nil];
    self.results = grabber.results;
}

@end
