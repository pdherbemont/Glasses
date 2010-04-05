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

#import <Cocoa/Cocoa.h>

#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_5

@interface NSMenu (ShowLeopardAdditions)
- (void)removeAllItems;
@end

@interface NSURL (SnowLeopardAdditions)
- (NSString *)lastPathComponent;
- (NSURL *)URLByAppendingPathComponent:(NSString *)component;
@end

enum {
    /* The mounted volume enumeration will skip hidden volumes.
     */
    NSVolumeEnumerationSkipHiddenVolumes = 1UL << 1,

    /* The mounted volume enumeration will produce file reference URLs rather than path-based URLs.
     */
    NSVolumeEnumerationProduceFileReferenceURLs = 1UL << 2
};
typedef NSUInteger NSVolumeEnumerationOptions;

@interface NSFileManager (SnowLeopardAdditions)
- (NSArray *)mountedVolumeURLsIncludingResourceValuesForKeys:(NSArray *)propertyKeys options:(NSVolumeEnumerationOptions)options;
- (BOOL)removeItemAtURL:(NSURL *)URL error:(NSError **)error;
@end


#endif
