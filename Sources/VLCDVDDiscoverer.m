//
//  VLCDVDDiscoverer.m
//  Lunettes
//
//  Created by Moi on 12/02/10.
//  Copyright 2010 école Centrale de Lyon. All rights reserved.
//

#import "VLCDVDDiscoverer.h"
#import <VLCKit/VLCKit.h>

#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_5
#import "VLCCompatibilityAdditions.h"
#endif

@implementation VLCDVDDiscoverer

- (id)init
{
    self = [super init];
    if (!self)
        return nil;
    localizedName = @"DVD";

    NSNotificationCenter *center = [[NSWorkspace sharedWorkspace] notificationCenter];
    [center addObserver:self selector:@selector(updateDVDList:) name:NSWorkspaceDidUnmountNotification object:nil];
    [center addObserver:self selector:@selector(updateDVDList:) name:NSWorkspaceDidMountNotification object:nil];

    [self updateDVDList:nil];
    return self;
}

- (void)updateDVDList:(NSNotification *)notification
{
    NSFileManager * fileManager = [NSFileManager defaultManager];
    NSArray *volumes = [fileManager mountedVolumeURLsIncludingResourceValuesForKeys:NULL options:NSVolumeEnumerationSkipHiddenVolumes];

    NSMutableArray *DVDs = [[NSMutableArray alloc] init];

    for (NSURL *volumeURL in volumes) {
        NSURL *potentialDVDURL = [volumeURL URLByAppendingPathComponent:@"VIDEO_TS"];
        if ([fileManager fileExistsAtPath:[potentialDVDURL path]]) {
            VLCMedia *DVD = [[VLCMedia alloc] initWithURL:potentialDVDURL];
            NSString *title = [[volumeURL lastPathComponent] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
            [DVD setValue:title forMeta:@"title"];
            [DVDs addObject:DVD];
            [DVD release];
        }
    }

    VLCMediaList *DVDList = [[VLCMediaList alloc] initWithArray:DVDs];
    [DVDs release];

    [self willChangeValueForKey:@"discoveredMedia"];
    [discoveredMedia release];
    discoveredMedia = DVDList;
    [self didChangeValueForKey:@"discoveredMedia"];

    running = NO;
}

- (void) dealloc
{
    NSNotificationCenter *center = [[NSWorkspace sharedWorkspace] notificationCenter];
    [center removeObserver:self name:NSWorkspaceDidUnmountNotification object:nil];
    [center removeObserver:self name:NSWorkspaceDidMountNotification object:nil];
    [super dealloc];
}

@end
