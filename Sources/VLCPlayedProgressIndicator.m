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

    bounds.size.height -= 0;
    bounds.size.width -= 0;

    NSRect originalBounds = bounds;

    bounds.size.width -= 2;

    double scale = [self maxValue] - [self minValue];
    if (scale > 0)
        bounds.size.width *= [self doubleValue] / scale;
	NSBezierPath *border = [NSBezierPath bezierPathWithRect:originalBounds];
    if (!NSIsEmptyRect(originalBounds)) {
		NSColor *baseColor = [NSColor colorWithCalibratedRed:0.95 green:0.95 blue:0.95 alpha:1.0];
		NSColor *color2 = [NSColor colorWithCalibratedRed:0.95 * 0.95 green:0.95 * 0.95 blue:0.95 * 0.95 alpha: 1.0];
		NSColor *color3 = [NSColor colorWithCalibratedRed: 0.95 * 0.85 green: 0.95 * 0.85 blue: 0.95 * 0.85 alpha: 1.0];
		NSGradient *gradient = [[NSGradient alloc] initWithColorsAndLocations: baseColor, 0.0, color2, 0.5, color3, 0.5, baseColor, 1.0, nil];
        [gradient drawInBezierPath:border angle:90];
        [gradient release];
		[border setLineWidth:1];
		[[NSColor colorWithCalibratedWhite:0.714 alpha:1.000] set];
		[border stroke];
    }

    if (!NSIsEmptyRect(bounds)) {
		NSBezierPath *content = [NSBezierPath bezierPathWithRect:bounds];
		NSColor *baseColor = [NSColor colorWithCalibratedRed:0.346 green:0.660 blue:0.968 alpha:0.95];
		NSColor *color2 = [NSColor colorWithCalibratedRed:0.346 * 0.95 green:0.660 * 0.95 blue:0.968 * 0.95 alpha: 1.0];
		NSColor *color3 = [NSColor colorWithCalibratedRed:0.346 * 0.85 green:0.660 * 0.85 blue:0.968 * 0.85 alpha: 1.0];
		NSGradient *gradient = [[NSGradient alloc] initWithColorsAndLocations: baseColor, 0.0, color2, 0.5, color3, 0.5, baseColor, 1.0, nil];
        [gradient drawInBezierPath:content angle:90];
        [gradient release];
        [content setLineWidth:1];
        [[NSColor colorWithCalibratedRed:0.267 green:0.506 blue:0.741 alpha:1.000] set];
        [content stroke];
    }

}

- (void)mouseDown:(NSEvent *)theEvent
{
    // By-pass NSSlider mouseDown implementation.
    [[self nextResponder] tryToPerform:@selector(mouseDown:) with:theEvent];
}

- (NSGradient *)progressGradientForColor:(NSColor *)baseColor
{
    //NSColor * baseColor = [NSColor colorWithCalibratedRed: redComponent green: greenComponent blue: blueComponent alpha: 1.0];
	//NSColor * color2 = [NSColor colorWithCalibratedRed: redComponent * 0.95 green: greenComponent * 0.95 blue: blueComponent * 0.95 alpha: 1.0];
    NSColor *color2 = [NSColor colorWithCalibratedRed:[baseColor redComponent] * 0.95 green:[baseColor greenComponent] * 0.95 blue:[baseColor blueComponent] * 0.95 alpha:1.0];
	//NSColor * color3 = [NSColor colorWithCalibratedRed: redComponent * 0.85 green: greenComponent * 0.85 blue: blueComponent * 0.85 alpha: 1.0];
	NSColor *color3 = [NSColor colorWithCalibratedRed:[baseColor redComponent] * 0.85 green:[baseColor greenComponent] * 0.85 blue:[baseColor blueComponent] * 0.85 alpha: 1.0];
    NSGradient * progressGradient = [[NSGradient alloc] initWithColorsAndLocations: baseColor, 0.0, color2, 0.5, color3, 0.5, baseColor, 1.0, nil];
    return [progressGradient autorelease];
}

@end
