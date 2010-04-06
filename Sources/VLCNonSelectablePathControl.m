//
//  VLCNonSelectablePathControl.m
//  Lunettes
//
//  Created by Pierre d'Herbemont on 4/6/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "VLCNonSelectablePathControl.h"

@implementation VLCNonSelectablePathControl
- (NSView *)hitTest:(NSPoint)point
{
    return nil;
}
@end
