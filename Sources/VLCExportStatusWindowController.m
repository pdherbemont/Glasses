//
//  VLCExportStatusWindowController.m
//  Lunettes
//
//  Created by Pierre d'Herbemont on 12/2/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "VLCExportStatusWindowController.h"


@implementation VLCExportStatusWindowController
@synthesize streamSession=_streamSession;
- (NSString *)windowNibName
{
	return @"ExportStatusWindow";
}

- (void)dealloc
{
    [_streamSession release];
    if (_theUpdateTimer) {
        [_theUpdateTimer invalidate];
        [_theUpdateTimer release];
    }
    [super dealloc];
}

- (IBAction)cancel:(id)sender
{
    [_streamSession stopStreaming];
    [self close];
}

- (void)windowDidLoad
{
    _theUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:0.3
                                                       target:self
                                                     selector:@selector(updateWindowState)
                                                     userInfo:nil
                                                      repeats:YES];
    [[self window] center];
}

-(void)updateWindowState
{
    if (_streamSession.isComplete) {
        [_theUpdateTimer invalidate];
        [[self window] orderOut:nil];
    }
}
@end
