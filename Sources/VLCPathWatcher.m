//
//  VLCPathWatcher.m
//  Lunettes
//
//  Created by Pierre d'Herbemont on 12/11/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "VLCPathWatcher.h"

#include <CoreServices/CoreServices.h>

@interface VLCPathWatcher (Private)
- (void)notifyChanges;
@end


static void callback(ConstFSEventStreamRef streamRef, void *clientCallBackInfo,
                     size_t numEvents,
                     void *eventPaths,
                     const FSEventStreamEventFlags eventFlags[],
                     const FSEventStreamEventId eventIds[])
{
    id self = clientCallBackInfo;
    [self notifyChanges];
}

@implementation VLCPathWatcher
- (id)initWithFilePathArray:(NSArray *)filePaths
{
    self = [super init];
    if (!self)
        return nil;

    FSEventStreamContext context;
    memset(&context, 0, sizeof(context));
    context.info = self;

#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    _stream = FSEventStreamCreate(NULL, callback, &context,
                                  (CFArrayRef)filePaths,
                                  kFSEventStreamEventIdSinceNow, /* Or a previous event ID */
                                  1.0, /* Latency in seconds */
                                  kFSEventStreamCreateFlagWatchRoot | kFSEventStreamCreateFlagIgnoreSelf);
#else
    _stream = FSEventStreamCreate(NULL, callback, &context,
                                  (CFArrayRef)filePaths,
                                  kFSEventStreamEventIdSinceNow, /* Or a previous event ID */
                                  1.0, /* Latency in seconds */
                                  kFSEventStreamCreateFlagWatchRoot);
#endif
    return self;
}

- (void)dealloc
{
    VLCAssert(!_started, @"Shouldn't be started");
    [self stop];
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    Block_release(_block);
#endif
    FSEventStreamRelease(_stream);
    [super dealloc];
}

#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
- (void)startWithBlock:(void (^)(void))block
{
    _started = YES;
    Block_release(_block);
    _block = Block_copy((void *)block);
    FSEventStreamScheduleWithRunLoop(_stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    FSEventStreamStart(_stream);
}
#endif

#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_5
- (void)startWithDelegate:(id)frame
{
    _started = YES;
    _delegate = frame;
    FSEventStreamScheduleWithRunLoop(_stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    FSEventStreamStart(_stream);
}
#endif

- (void)stop
{
    if (_started) {
        FSEventStreamStop(_stream);
        FSEventStreamInvalidate(_stream); /* will remove from runloop */
    }
    _started = NO;
}

- (void)notifyChanges
{
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    _block();
#else
    [_delegate pathWatcherDidChange:self];
#endif
}
@end
