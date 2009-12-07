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

- (IBAction)cancel:(id)sender
{
    NSLog(@"Cancel");
}
@end
