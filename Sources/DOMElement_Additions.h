//
//  DOMElement_Additions.h
//  Lunettes
//
//  Created by Pierre d'Herbemont on 8/22/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <WebKit/WebKit.h>

@interface DOMElement (VLCAdditions)
- (NSPoint)absolutePosition;
- (NSRect)frameInView:(NSView *)view;
@end
