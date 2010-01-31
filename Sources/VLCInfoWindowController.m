//
//  VLCInfoWindowController.m
//  Lunettes
//
//  Created by Pierre d'Herbemont on 1/31/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "VLCInfoWindowController.h"
#import "VLCDocumentController.h"

@implementation VLCInfoWindowController
- (NSString *)windowNibName
{
    return @"InfoWindow";
}

- (VLCDocumentController *)documentController
{
    return [VLCDocumentController sharedDocumentController];
}

- (void)windowWillClose:(NSNotification *)notification
{
    [[VLCDocumentController sharedDocumentController] closeInfoWindow];
}
@end
