//
//  VLCTitleDecrapifier.m
//  Lunettes
//
//  Created by Pierre d'Herbemont on 5/6/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "VLCTitleDecrapifier.h"


@implementation VLCTitleDecrapifier
+ (NSString *)decrapify:(NSString *)string
{
    if (!string)
        return nil;
    static NSArray *ignoredWords = nil;
    if (!ignoredWords) {
        ignoredWords = [[NSArray alloc] initWithObjects:
                        @"xvid", @"h264", @"dvd", @"rip", @"[fr]", nil];
    }
    NSMutableString *mutableString = [NSMutableString stringWithString:string];
    for (NSString *word in ignoredWords)
        [mutableString replaceOccurrencesOfString:word withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [mutableString length])];
    [mutableString replaceOccurrencesOfString:@"." withString:@" " options:NSCaseInsensitiveSearch range:NSMakeRange(0, [mutableString length])];
    return mutableString;
}

static inline BOOL isDigit(char c)
{
    return c >= '0' && c <= '9';
}

+ (BOOL)isTVShowEpisodeTitle:(NSString *)string
{
    const char *str = [[string lowercaseString] UTF8String];

    // Search for s01e10.
    for (unsigned i = 0; str[i]; i++) {
        if (str[i] == 's' &&
            isDigit(str[i+1]) &&
            isDigit(str[i+2]) &&
            str[i+3] == 'e' &&
            isDigit(str[i+4]) &&
            isDigit(str[i+5]))
        {
            return YES;
        }
    }
    return NO;
}

static inline int intFromChar(char n)
{
    return n - '0';
}

static inline NSNumber *numberFromTwoChars(char high, char low)
{
    return [NSNumber numberWithInt:intFromChar(high) * 10 + intFromChar(low)];
}

+ (NSDictionary *)tvShowEpisodeInfoFromString:(NSString *)string
{
    if (string && ![string isEqualToString:[NSString string]] && [string length] != 0)
    {
        const char *str = [[string lowercaseString] UTF8String];

        // Search for s01e10.
        for (unsigned i = 0; str[i]; i++) {
            if (str[i] == 's' &&
                isDigit(str[i+1]) &&
                isDigit(str[i+2]) &&
                str[i+3] == 'e' &&
                isDigit(str[i+4]) &&
                isDigit(str[i+5]))
            {
                NSNumber *season = numberFromTwoChars(str[i+1], str[i+2]);
                NSNumber *episode = numberFromTwoChars(str[i+4], str[i+5]);
                NSString *tvShowName = i > 0 ? [[string lowercaseString] substringToIndex:i-1] : nil;
                tvShowName = tvShowName ? [[VLCTitleDecrapifier decrapify:tvShowName] capitalizedString] : nil;
                return [NSDictionary dictionaryWithObjectsAndKeys:season, @"season", episode, @"episode", tvShowName, @"tvShowName", nil];
            }
        }
    }
    return nil;
}
@end
