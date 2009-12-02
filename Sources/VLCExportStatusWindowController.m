//
//  VLCExportStatusWindowController.m
//  Lunettes
//
//  Created by Pierre d'Herbemont on 12/2/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "VLCExportStatusWindowController.h"


/**********************************************************
 * First off, some value transformer to easily play with
 * bindings
 */
@interface VLCFloat10000FoldTransformer : NSObject
@end

@implementation VLCFloat10000FoldTransformer

+ (void)load
{
    VLCFloat10000FoldTransformer *float10000fold;
    float10000fold = [[VLCFloat10000FoldTransformer alloc] init];
    [NSValueTransformer setValueTransformer:(id)float10000fold forName:@"Float10000FoldTransformer"];
    [float10000fold release];
}

+ (Class)transformedValueClass
{
    return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

- (id)transformedValue:(id)value
{
    if( !value ) return nil;
    
    if(![value respondsToSelector: @selector(floatValue)])
    {
        [NSException raise: NSInternalInconsistencyException
                    format: @"Value (%@) does not respond to -floatValue.",
         [value class]];
        return nil;
    }
    
    return [NSNumber numberWithFloat: [value floatValue]*10000.];
}

- (id)reverseTransformedValue:(id)value
{
    if( !value ) return nil;
    
    if(![value respondsToSelector: @selector(floatValue)])
    {
        [NSException raise: NSInternalInconsistencyException
                    format: @"Value (%@) does not respond to -floatValue.",
         [value class]];
        return nil;
    }
    
    return [NSNumber numberWithFloat: [value floatValue]/10000.];
}
@end



@implementation VLCExportStatusWindowController
@synthesize streamSession=_streamSession;
- (NSString *)windowNibName
{
	return @"ExportStatusWindow";
}

- (IBAction)cancel:(id)sender
{
    NSLog(@"Cancel");
}
@end
