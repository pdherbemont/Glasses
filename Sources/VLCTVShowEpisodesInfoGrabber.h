//
//  VLCTVShowEpisodesInfoGrabber.h
//  Lunettes
//
//  Created by Pierre d'Herbemont on 5/24/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol VLCTVShowEpisodesInfoGrabberDelegate;

@interface VLCTVShowEpisodesInfoGrabber : NSObject {
    NSURLConnection *_connection;
    NSMutableData *_data;
    NSArray *_results;
    id<VLCTVShowEpisodesInfoGrabberDelegate> _delegate;
    void (^_block)();
}

@property (readwrite, assign) id<VLCTVShowEpisodesInfoGrabberDelegate> delegate;
@property (readonly, retain) NSArray *results;

- (void)lookUpForShowID:(NSString *)id;
- (void)lookUpForShowID:(NSString *)id andExecuteBlock:(void (^)())block;

@end

@protocol VLCTVShowEpisodesInfoGrabberDelegate <NSObject>
@optional
- (void)tvShowEpisodesInfoGrabber:(VLCTVShowEpisodesInfoGrabber *)grabber didFailWithError:(NSError *)error;
- (void)tvShowEpisodesInfoGrabberDidFinishGrabbing:(VLCTVShowEpisodesInfoGrabber *)grabber;
@end
