//
//  VLCValueTransformers.m
//  Lunettes
//
//  Created by Pierre d'Herbemont on 12/6/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <VLCKit/VLCKit.h>
#import <WebKit/WebKit.h>

#import "VLCValueTransformers.h"

@implementation VLCFloat10000FoldTransformer

+ (void)load
{
    id transformer = [[self alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:@"Float10000FoldTransformer"];
    [transformer release];
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
    if (!value)
        return nil;

    if (![value respondsToSelector: @selector(floatValue)]) {
        [NSException raise:NSInternalInconsistencyException
                    format:@"Value (%@) does not respond to -floatValue.", [value class]];
        return nil;
    }

    return [NSNumber numberWithFloat: [value floatValue]*10000.];
}

- (id)reverseTransformedValue:(id)value
{
    if (!value)
        return nil;

    if (![value respondsToSelector: @selector(floatValue)]) {
        [NSException raise:NSInternalInconsistencyException
                    format:@"Value (%@) does not respond to -floatValue.", [value class]];
        return nil;
    }

    return [NSNumber numberWithFloat:[value floatValue] / 10000.];
}

@end


@implementation VLCRateToSliderTransformer

+ (void)load
{
    id transformer = [[self alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:@"RateToSliderTransformer"];
    [transformer release];
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
    if (!value)
        return nil;

    if (![value respondsToSelector: @selector(floatValue)]) {
        [NSException raise:NSInternalInconsistencyException
                    format:@"Value (%@) does not respond to -floatValue.", [value class]];
        return nil;
    }

    float val = [value floatValue];
    if (val <= 0)
        val = -6;
    else if (val < 1)
        val = 1 - 1 / val;
    else
        val -= 1;
    return [NSNumber numberWithFloat: val * 10000.];
}

- (id)reverseTransformedValue:(id)value
{
    if (!value)
        return nil;

    if (![value respondsToSelector: @selector(floatValue)]) {
        [NSException raise:NSInternalInconsistencyException
                    format:@"Value (%@) does not respond to -floatValue.", [value class]];
        return nil;
    }
    float val = [value floatValue] / 10000.;
    if (val < 0)
        val = 1 / (1 - val);
    else {
        val = val + 1;
    }

    return [NSNumber numberWithFloat:val];
}

@end

@implementation VLCDictionaryValuesToArray

+ (void)load
{
    id transformer = [[self alloc] init];
    [NSValueTransformer setValueTransformer:(id)transformer forName:@"DictionaryValuesToArray"];
    [transformer release];
}

+ (Class)transformedValueClass
{
    return [NSDictionary class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)value
{
    if (!value)
        return nil;

    if (![value respondsToSelector: @selector(allValues)]) {
        [NSException raise:NSInternalInconsistencyException
                    format:@"Value (%@) does not respond to -allValues.", [value class]];
        return nil;
    }

    return [value allValues];
}

- (id)reverseTransformedValue:(id)value
{
    return nil;
}

@end

@implementation VLCTimeAsNumberToPrettyTime

+ (void)load
{
    id transformer = [[self alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:@"TimeAsNumberToPrettyTime"];
    [transformer release];
}

+ (Class)transformedValueClass
{
    return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)value
{
    if (!value)
        return nil;

    return [VLCTime timeWithNumber:value].verboseStringValue;
}

- (id)reverseTransformedValue:(id)value
{
    return nil;
}

@end

@implementation VLCStringToURL

+ (void)load
{
    id transformer = [[self alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:@"StringToURL"];
    [transformer release];
}

+ (Class)transformedValueClass
{
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

- (id)transformedValue:(id)value
{
    if (!value)
        return nil;

    return [NSURL fileURLWithPath:value];
}

- (id)reverseTransformedValue:(id)value
{
    if (!value)
        return nil;

    return [value absoluteURL];
}

@end

@implementation VLCWebScriptObjectToIndexSet

+ (void)load
{
    id transformer = [[self alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:@"VLCWebScriptObjectToIndexSet"];
    [transformer release];
}

+ (Class)transformedValueClass
{
    return [WebScriptObject class];
}

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

- (id)transformedValue:(id)value
{
    if (![value isKindOfClass:[WebScriptObject class]])
        return nil;

    NSMutableIndexSet *set = [NSMutableIndexSet indexSet];
    for (NSUInteger i = 0;; i++) {
        id val = [value webScriptValueAtIndex:i];
        if ([val isKindOfClass:[WebUndefined class]])
            break;
        if (![val isKindOfClass:[NSNumber class]])
            continue;
        [set addIndex:[val unsignedIntValue]];
    }
    return set;
}

- (id)reverseTransformedValue:(id)value
{
    if (![value isKindOfClass:[NSIndexSet class]])
        return nil;
    NSIndexSet *set = value;
    NSMutableArray *array = [NSMutableArray array];
    NSUInteger index = [set firstIndex];
    do {
        [array addObject:[NSNumber numberWithUnsignedInt:index]];
    } while ((index = [set indexGreaterThanIndex:index]) != NSNotFound);
    return array;
}

@end
