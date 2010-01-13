//
//  DOMHTMLElement_Additions.m
//  Lunettes
//
//  Created by Pierre d'Herbemont on 10/8/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "DOMHTMLElement_Additions.h"


@implementation DOMHTMLElement (VLCAdditions)
- (BOOL)hasClassName:(NSString *)class
{
    NSString *currentClassName = self.className;
    if (!currentClassName)
        return NO;
    NSRange range = [currentClassName rangeOfString:class];
    return range.length > 0;
}
@end
