//
//  VLCMovieInfoGrabberWindowController
//  Lunettes
//
//  Created by Pierre d'Herbemont on 5/5/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "VLCMovieInfoGrabberWindowController.h"
#import "VLCDocumentController.h"

#import "VLCMovieInfoGrabber.h"

@interface VLCMovieInfoGrabberWindowController () <VLCMovieInfoGrabberDelegate>
@property (readwrite, retain) NSArray *results;
@end

@implementation VLCMovieInfoGrabberWindowController
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
    return @"MovieInfoGrabberWindow";
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
        _grabber = [[VLCMovieInfoGrabber alloc] init];
        [_grabber setDelegate:self];
    }
    [_grabber lookUpForTitle:string];

    // We are now waiting for delegate methods
}

- (void)movieInfoGrabber:(VLCMovieInfoGrabber *)grabber didFailWithError:(NSError *)error
{
    [_progressIndicator stopAnimation:nil];
}

- (void)movieInfoGrabberDidFinishGrabbing:(VLCMovieInfoGrabber *)grabber
{
    [_progressIndicator stopAnimation:nil];
    self.results = grabber.results;
}

- (IBAction)applyToSelectedMedia:(id)sender
{
    VLCDocumentController *controller = [VLCDocumentController sharedDocumentController];

    NSArray *selectedResults = [_resultsArrayController selectedObjects];
    VLCAssert([selectedResults count] > 0, @"This action should not be triggered");
    NSDictionary *selectedResult = [selectedResults objectAtIndex:0];

    NSArray *selectedMedias = [[controller currentArrayController] selectedObjects];
    VLCAssert([selectedMedias count] > 0, @"This action should not be triggered");
    id selectedMedia = [selectedMedias objectAtIndex:0];

    if (![selectedMedia isKindOfClass:[NSManagedObject class]])
        NSBeep();
    NSManagedObject *file = selectedMedia;
    [file setValue:[selectedResult objectForKey:@"artworkURL"] forKey:@"artworkURL"];
    [file setValue:[selectedResult objectForKey:@"title"] forKey:@"title"];
    [file setValue:[selectedResult objectForKey:@"shortSummary"] forKey:@"shortSummary"];
    [file setValue:[selectedResult objectForKey:@"releaseYear"] forKey:@"releaseYear"];
}
@end
