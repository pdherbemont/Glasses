//
//  VLCArrayController.h
//  Lunettes
//
//  Created by Pierre d'Herbemont on 12/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface VLCArrayController : NSArrayController {
    NSString *_searchString;
}

@property (readwrite, retain) NSString *searchString;
@end
