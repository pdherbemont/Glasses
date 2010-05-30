//
//  VLCMovieInfoGrabber.h
//  Lunettes
//
//  Created by Pierre d'Herbemont on 5/6/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@protocol VLCMovieInfoGrabberDelegate;

@interface VLCMovieInfoGrabber : NSObject {
    NSURLConnection *_connection;
    NSMutableData *_data;
    NSArray *_results;
    id<VLCMovieInfoGrabberDelegate> _delegate;
    void (^_block)(NSError *);
}

@property (readwrite, assign) id<VLCMovieInfoGrabberDelegate> delegate;
@property (readonly, retain) NSArray *results;

- (void)lookUpForTitle:(NSString *)title;
- (void)lookUpForTitle:(NSString *)title andExecuteBlock:(void (^)(NSError *))block;

@end

@protocol VLCMovieInfoGrabberDelegate <NSObject>
@optional
- (void)movieInfoGrabber:(VLCMovieInfoGrabber *)grabber didFailWithError:(NSError *)error;
- (void)movieInfoGrabberDidFinishGrabbing:(VLCMovieInfoGrabber *)grabber;
@end
