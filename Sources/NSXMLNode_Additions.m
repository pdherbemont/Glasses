//
//  NSXMLNode_Additions.m
//  Lunettes
//
//  Created by Pierre d'Herbemont on 5/6/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "NSXMLNode_Additions.h"


@implementation NSXMLNode (VLCAdditions)

- (NSString *)stringValueForXPath:(NSString *)string
{
    NSArray *nodes = [self nodesForXPath:string error:nil];
    if ([nodes count] == 0)
        return nil;
    return [[nodes objectAtIndex:0] stringValue];
}

@end
