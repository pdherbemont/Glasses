//
//  VLCExportStatusWindowController.h
//  Lunettes
//
//  Created by Pierre d'Herbemont on 12/2/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <VLCKit/VLCKit.h>


@interface VLCExportStatusWindowController : NSWindowController {
    VLCStreamSession *_streamSession;
    NSTimer *_theUpdateTimer;
}

@property (readwrite, retain) VLCStreamSession *streamSession;
- (IBAction)cancel:(id)sender;
- (void)updateWindowState;
@end
