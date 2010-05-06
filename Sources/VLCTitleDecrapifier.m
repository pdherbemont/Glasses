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
    static NSArray *ignoredWords = nil;
    if (!ignoredWords) {
        ignoredWords = [[NSArray alloc] initWithObjects:
                        @"xvid", @"h264", @"dvd", @"rip", @"[fr]", nil];
    }
    NSMutableString *lowercase = [NSMutableString stringWithString:[string lowercaseString]];
    for (NSString *word in ignoredWords)
        [lowercase replaceOccurrencesOfString:word withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [lowercase length])];
    return lowercase;
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
@end
