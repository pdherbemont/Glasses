//
//  VLCPlayedProgressIndicator.m
//  Lunettes
//
//  Created by Pierre d'Herbemont on 12/7/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "VLCPlayedProgressIndicator.h"

@implementation VLCPlayedProgressIndicator

- (void)drawRect:(NSRect)rect
{
    // Draw default to make sure the slider behaves correctly
    
    NSRect bounds = [self bounds];

    bounds.origin.x += 2;
    bounds.origin.y += 2;
    
    bounds.size.height -= 4;
    bounds.size.width -= 4;
    
    NSRect originalBounds = bounds;

    bounds.origin.x += 1;
    bounds.origin.y += 1;
    
    bounds.size.height -= 2;
    bounds.size.width -= 2;
    
    double scale = [self maxValue] - [self minValue];
    if (scale > 0)
        bounds.size.width *= [self doubleValue] / scale;

    if (!NSIsEmptyRect(originalBounds)) {
        NSBezierPath *border = [NSBezierPath bezierPathWithRoundedRect:originalBounds xRadius:4 yRadius:4];

        NSGradient *gradient = [[NSGradient alloc] initWithColorsAndLocations:
                                [NSColor colorWithDeviceWhite:0.3 alpha:1], 0.0,
                                [NSColor colorWithDeviceWhite:0.4 alpha:1], 0.1,
                                [NSColor colorWithDeviceWhite:0.5 alpha:1], 0.9,
                                [NSColor colorWithDeviceWhite:0.55 alpha:1], 1.0, nil];
        [gradient drawInBezierPath:border angle:90];
        [gradient release];
    }

    if (!NSIsEmptyRect(bounds)) {
        NSBezierPath *content = [NSBezierPath bezierPathWithRoundedRect:bounds xRadius:4 yRadius:4];
        NSGradient *gradient = [[NSGradient alloc] initWithColorsAndLocations:
                    [NSColor colorWithDeviceWhite:0.8 alpha:1], 0.0,
                    [NSColor colorWithDeviceWhite:0.75 alpha:1], 0.4,
                    [NSColor colorWithDeviceWhite:0.7 alpha:1], 0.6,
                    [NSColor colorWithDeviceWhite:0.65 alpha:1], 1.0, nil];;
        [gradient drawInBezierPath:content angle:90];
        [gradient release];        
    }
}

- (void)mouseDown:(NSEvent *)theEvent
{
    // By-pass NSSlider mouseDown implementation.
    [[self nextResponder] tryToPerform:@selector(mouseDown:) with:theEvent];
}

@end
