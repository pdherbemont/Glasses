//
//  VLCTVShowEpisodesInfoGrabber.h
//  Lunettes
//
//  Created by Pierre d'Herbemont on 5/24/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class VLCURLConnection;

@protocol VLCTVShowEpisodesInfoGrabberDelegate;

@interface VLCTVShowEpisodesInfoGrabber : NSObject {
    VLCURLConnection *_connection;
    NSDictionary *_results;
    NSArray *_episodesResults;
    id<VLCTVShowEpisodesInfoGrabberDelegate> _delegate;
    void (^_block)();
}

@property (readwrite, assign) id<VLCTVShowEpisodesInfoGrabberDelegate> delegate;
@property (readonly, retain) NSArray *episodesResults;
@property (readonly, retain) NSDictionary *results;

- (void)lookUpForShowID:(NSString *)id;
- (void)lookUpForShowID:(NSString *)id andExecuteBlock:(void (^)())block;

@end

@protocol VLCTVShowEpisodesInfoGrabberDelegate <NSObject>
@optional
- (void)tvShowEpisodesInfoGrabber:(VLCTVShowEpisodesInfoGrabber *)grabber didFailWithError:(NSError *)error;
- (void)tvShowEpisodesInfoGrabberDidFinishGrabbing:(VLCTVShowEpisodesInfoGrabber *)grabber;
@end
