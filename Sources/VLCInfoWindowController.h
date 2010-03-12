//
//  VLCInfoWindowController.h
//  Lunettes
//
//  Created by Pierre d'Herbemont on 1/31/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class VLCDocumentController;

@interface VLCInfoWindowController : NSWindowController {

}

/**
 * Used by the xib bindings.
 */
@property (readonly, retain) VLCDocumentController *documentController;

- (IBAction)tvShowNameChanged:(id)sender;
@end
