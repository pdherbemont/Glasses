//
//  VLCPlayedProgressIndicator.h
//  Lunettes
//
//  Created by Pierre d'Herbemont on 12/7/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface VLCPlayedProgressIndicator : NSSlider {

}
- (NSGradient *)progressGradientForColor:(NSColor *)baseColor;
@end
