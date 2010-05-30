//
//  VLCTVShowInfoGrabber.h
//  Lunettes
//
//  Created by Pierre d'Herbemont on 5/6/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol VLCTVShowInfoGrabberDelegate;

@interface VLCTVShowInfoGrabber : NSObject {
    NSURLConnection *_connection;
    NSMutableData *_data;
    NSArray *_results;
    void (^_block)();
    id<VLCTVShowInfoGrabberDelegate> _delegate;
}

@property (readwrite, assign) id<VLCTVShowInfoGrabberDelegate> delegate;
@property (readonly, retain) NSArray *results;

- (void)lookUpForTitle:(NSString *)title;
- (void)lookUpForTitle:(NSString *)title andExecuteBlock:(void (^)())block;

+ (void)fetchServerTimeAndExecuteBlock:(void (^)(NSNumber *))block;
+ (void)fetchUpdatesSinceServerTime:(NSNumber *)serverTime andExecuteBlock:(void (^)(NSArray *))block;
@end


@protocol VLCTVShowInfoGrabberDelegate <NSObject>
@optional
- (void)tvShowInfoGrabber:(VLCTVShowInfoGrabber *)grabber didFailWithError:(NSError *)error;
- (void)tvShowInfoGrabberDidFinishGrabbing:(VLCTVShowInfoGrabber *)grabber;
@end
