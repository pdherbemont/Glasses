//
//  VLCURLConnection.h
//  Lunettes
//
//  Created by Pierre d'Herbemont on 5/30/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class VLCURLConnection;

@interface VLCURLConnection : NSObject {
    NSMutableData *_data;
    NSURLConnection *_connection;
    void (^_block)(VLCURLConnection *connection, NSError *);
}

@property (readonly, retain) NSData *data;

+ (id)runConnectionWithURL:(NSURL *)url andBlock:(void (^)(VLCURLConnection *connection, NSError *error))block;

- (void)loadURL:(NSURL *)url andPerformBlock:(void (^)(VLCURLConnection *connection, NSError *error))block;
- (void)cancel;
@end
