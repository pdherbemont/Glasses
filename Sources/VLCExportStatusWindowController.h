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
}

@property (readwrite, retain) VLCStreamSession *streamSession;
- (IBAction)cancel:(id)sender;
@end
