//
//  VLCValueTransformers.m
//  Lunettes
//
//  Created by Pierre d'Herbemont on 12/6/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <VLCKit/VLCKit.h>

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

@implementation VLCStringURLToFileName

+ (void)load
{
    id transformer = [[self alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:@"StringURLToFileName"];
    [transformer release];
}

+ (Class)transformedValueClass
{
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

static inline BOOL is_num(char c)
{
    return c >= '0' && c <= '9';
}

- (id)transformedValue:(id)value
{

    NSString *name = [[value lastPathComponent] stringByDeletingPathExtension];
    name = [name stringByReplacingOccurrencesOfString:@"." withString:@" "];
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    __block NSInteger position = NSNotFound;
    [name enumerateSubstringsInRange:NSMakeRange(0, [name length]) options:NSStringEnumerationByWords
                          usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop){
                              // Match SXXEXX
                              if ([substring characterAtIndex:0] == 'S' && [substring length] >= 6) {
                                  if (is_num([substring characterAtIndex:1]) && is_num([substring characterAtIndex:2])) {
                                      if ([substring characterAtIndex:3] == 'E') {
                                          if (is_num([substring characterAtIndex:4]) && is_num([substring characterAtIndex:5])) {
                                              *stop = YES;
                                              position = substringRange.location;
                                          }
                                      }
                                  }

                              }
                          }];
#else
    /* FIXME: code missing here!" */
    NSInteger position = NSNotFound;
#endif
    if (position != NSNotFound) {
        name = [name substringToIndex:position + 6];
    }
    return name;
}

- (id)reverseTransformedValue:(id)value
{
    return nil;
}

@end

