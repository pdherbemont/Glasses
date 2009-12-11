//
//  VLCPathWatcher.h
//  Lunettes
//
//  Created by Pierre d'Herbemont on 12/11/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface VLCPathWatcher : NSObject {
    void *_stream;
    void (^_block)(void); 
}
- (id)initWithFilePathArray:(NSArray *)filePaths;

- (void)startWithBlock:(void (^)(void))block;
- (void)stop;
@end
