//
//  DOMHTMLElement_Additions.h
//  Lunettes
//
//  Created by Pierre d'Herbemont on 10/8/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <WebKit/WebKit.h>


@interface DOMHTMLElement (VLCAdditions)
- (BOOL)hasClassName:(NSString *)className;
@end
