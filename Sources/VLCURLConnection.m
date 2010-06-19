//
//  VLCURLConnection.m
//  Lunettes
//
//  Created by Pierre d'Herbemont on 5/30/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "VLCURLConnection.h"

@interface VLCURLConnection ()

- (void)loadURL:(NSURL *)url andPerformBlock:(void (^)(VLCURLConnection *connection, NSError *error))block;

@end


@implementation VLCURLConnection
@synthesize data=_data;
+ (id)runConnectionWithURL:(NSURL *)url andBlock:(void (^)(VLCURLConnection *connection, NSError *error))block
{
    id obj = [[[[self class] alloc] init] autorelease];
    [obj loadURL:url andPerformBlock:block];
    return obj;
}

- (void)dealloc
{
    if (_block)
        Block_release(_block);
    [_connection release];
    [_data release];
    [super dealloc];
}

- (void)loadURL:(NSURL *)url andPerformBlock:(void (^)(VLCURLConnection *connection, NSError *error))block
{
    if (_block)
        Block_release(_block);
    _block = block ? Block_copy(block) : NULL;

    [_data release];
    _data = [[NSMutableData alloc] init];

    NSURLRequest *request = [[[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:15] autorelease];
    [_connection cancel];
    [_connection release];
    _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];

    // Make sure we are around during the request
    [self retain];
}

- (void)cancel
{
    [_connection cancel];
    [_connection release];
    _connection = nil;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    // Call the call back with the error.
    _block(self, error);

    // Release the eventual block. This prevents ref cycle.
    if (_block) {
        Block_release(_block);
        _block = NULL;
    }

    // This balances the -retain in -load
    [self autorelease];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [_data appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // Call the call back with the data.
    _block(self, nil);

    // Release the eventual block. This prevents ref cycle.
    if (_block) {
        Block_release(_block);
        _block = NULL;
    }

    // This balances the -retain in -load
    [self autorelease];
}
@end
