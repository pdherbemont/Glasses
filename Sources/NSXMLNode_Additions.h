//
//  NSXMLNode_Additions.h
//  Lunettes
//
//  Created by Pierre d'Herbemont on 5/6/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSXMLNode (VLCAdditions)
- (NSString *)stringValueForXPath:(NSString *)string;
- (NSNumber *)numberValueForXPath:(NSString *)string;
@end
