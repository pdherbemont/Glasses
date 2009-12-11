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

    _stream = FSEventStreamCreate(NULL, callback, &context,
                                  (CFArrayRef)filePaths,
                                  kFSEventStreamEventIdSinceNow, /* Or a previous event ID */
                                  1.0, /* Latency in seconds */
                                  kFSEventStreamCreateFlagWatchRoot | kFSEventStreamCreateFlagIgnoreSelf);
    return self;
}

- (void) dealloc
{
    Block_release(_block);
    FSEventStreamRelease(_stream);
    [super dealloc];
}

- (void)startWithBlock:(void (^)(void))block
{
    Block_release(_block);
    _block = Block_copy(block);
    FSEventStreamScheduleWithRunLoop(_stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    FSEventStreamStart(_stream);
}

- (void)stop
{
    FSEventStreamStop(_stream);
    FSEventStreamInvalidate(_stream); /* will remove from runloop */
}

- (void)notifyChanges
{
    _block();
}
@end
