//
//  VLCPathWatcher.h
//  Lunettes
//
//  Created by Pierre d'Herbemont on 12/11/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_5
#import <WebKit/WebKit.h>
#endif

@interface VLCPathWatcher : NSObject {
    void *_stream;
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    void (^_block)(void);
#else
    id _delegate;
#endif
    BOOL _started;
}
- (id)initWithFilePathArray:(NSArray *)filePaths;

#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
- (void)startWithBlock:(void (^)(void))block;
#else
- (void)startWithDelegate:(id)frame;
#endif
- (void)stop;
@end

@interface NSObject (FileDelegate)
- (void)pathWatcherDidChange:(VLCPathWatcher *)pathWatcher;
@end
