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

@interface VLCDVDDiscoverer (Internal)
- (void)registerNotifications;
@end

@implementation VLCDVDDiscoverer

- (id)init
{
    self = [super init];
    if (!self)
        return nil;
    localizedName = @"DVD";
    discoveredMedia = [[VLCMediaList alloc] init];

    [self performSelectorInBackground:@selector(registerNotifications) withObject:nil];
    return self;
}

- (void)registerNotifications
{
    NSNotificationCenter *center = [[NSWorkspace sharedWorkspace] notificationCenter];

    // Somehow this methods cost a lot and may block for several seconds.
    // This is why we are calling this from non main thread.

    // FIXME- it is unclear if this is thread safe or not.
    // We'll probably have to use the lower level API.
    [center addObserver:self selector:@selector(updateDVDList:) name:NSWorkspaceDidUnmountNotification object:nil];
    [center addObserver:self selector:@selector(updateDVDList:) name:NSWorkspaceDidMountNotification object:nil];

    [self updateDVDList:nil];
}

- (void)updateDVDList:(NSNotification *)notification
{
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:_cmd withObject:notification waitUntilDone:YES];
        return;
    }

    VLCAssertMainThread();
    NSFileManager * fileManager = [NSFileManager defaultManager];
    NSArray *volumes = [fileManager mountedVolumeURLsIncludingResourceValuesForKeys:NULL options:NSVolumeEnumerationSkipHiddenVolumes];

    NSMutableArray *DVDs = [[NSMutableArray alloc] init];

    for (NSURL *volumeURL in volumes) {
        NSURL *potentialDVDURL = [volumeURL URLByAppendingPathComponent:@"VIDEO_TS"];
        NSString *path = [potentialDVDURL path];

        // Fast path.
        if ([path isEqualToString:@"/"])
            continue;

        if ([fileManager fileExistsAtPath:path]) {
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

- (void)dealloc
{
    NSNotificationCenter *center = [[NSWorkspace sharedWorkspace] notificationCenter];
    [center removeObserver:self name:NSWorkspaceDidUnmountNotification object:nil];
    [center removeObserver:self name:NSWorkspaceDidMountNotification object:nil];
    [super dealloc];
}

@end
