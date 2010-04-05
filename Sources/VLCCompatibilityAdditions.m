/*****************************************************************************
 * Copyright (C) 2010 the VideoLAN team
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan dot org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/

#import "VLCCompatibilityAdditions.h"
#import <ApplicationServices/ApplicationServices.h>

#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_5

@implementation NSMenu (ShowLeopardAdditions)
- (void)removeAllItems
{
    int count = [self numberOfItems];
    for (int x = count; x < count; x++)
        [self removeItemAtIndex:x];
}

@end

@implementation NSURL (SnowLeopardAdditions)
- (NSString *)lastPathComponent
{
    NSString *stringRepresentation = [self absoluteString];
    return([stringRepresentation lastPathComponent]);
}

- (NSURL *)URLByAppendingPathComponent:(NSString *)component
{
    /* this replacement behaves the same way as the original and therefore checks whether there
       is a slash as last character or not. If not, it's added prior to the appended component */
    NSString *stringRepresentation = [self absoluteString];
    NSRange lastChar;
    lastChar.length=1;
    lastChar.location=[stringRepresentation length] - 1;
    if ([[stringRepresentation substringWithRange:lastChar] isEqualToString:@"/"])
        return([NSURL URLWithString:[stringRepresentation stringByAppendingString:component]]);
    else
        return([NSURL URLWithString:[stringRepresentation stringByAppendingFormat:@"/%@", component]]);
}
@end

static BOOL isInvisible(NSString *path);

@implementation NSFileManager (SnowLeopardAdditions)

BOOL isInvisible(NSString *path)
{
    CFURLRef urlRef = CFURLCreateWithFileSystemPath( kCFAllocatorDefault, (CFStringRef)path, kCFURLPOSIXPathStyle, YES);
    LSItemInfoRecord itemInfo;
    LSCopyItemInfoForURL(urlRef, kLSRequestAllFlags, &itemInfo);

    BOOL isInvisible = itemInfo.flags & kLSItemInfoIsInvisible;
    CFRelease(urlRef);
    return isInvisible;
}

- (NSArray *)mountedVolumeURLsIncludingResourceValuesForKeys:(NSArray *)propertyKeys options:(NSVolumeEnumerationOptions)options
{
    /* this replacement's behavior differs from the original as it doesn't take the propertyKeys into account at all
       additionally, the original doesn't behave as expected as it always returns file references paths. That's why we do, too */ 
    NSArray *mountedVolumes = [[NSWorkspace sharedWorkspace] mountedLocalVolumePaths];
    NSMutableArray *URLsToReturn = [NSMutableArray arrayWithCapacity:[mountedVolumes count]];

    for (NSUInteger x = 0; x < [mountedVolumes count]; x++) {
        if (options & NSVolumeEnumerationSkipHiddenVolumes) {
            if (isInvisible([mountedVolumes objectAtIndex:x]))
                continue;
        }

        [URLsToReturn addObject:[NSURL fileURLWithPath:[mountedVolumes objectAtIndex:x]]];
    }

    return URLsToReturn;
}

- (BOOL)removeItemAtURL:(NSURL *)URL error:(NSError **)error
{
    return [self removeItemAtPath:[URL filePathURL] error:error];
}

@end


#endif
