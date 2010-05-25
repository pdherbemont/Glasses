//
//  VLCTVShowEpisodesInfoGrabber.m
//  Lunettes
//
//  Created by Pierre d'Herbemont on 5/24/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "VLCTVShowEpisodesInfoGrabber.h"
#import "NSXMLNode_Additions.h"

#import "TheTVDBGrabber.h"

@interface VLCTVShowEpisodesInfoGrabber ()
@property (readwrite, retain) NSArray *results;
@end

@implementation VLCTVShowEpisodesInfoGrabber
@synthesize delegate=_delegate;
@synthesize results=_results;
- (void)dealloc
{
    [_data release];
    [_connection release];
    [_results release];
    if (_block)
        Block_release(_block);
    [super dealloc];
}

- (void)lookUpForShowID:(NSString *)showId
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:TVDB_QUERY_EPISODE_INFO, TVDB_HOSTNAME, TVDB_API_KEY, showId, TVDB_DEFAULT_LANGUAGE]];
    NSLog(@"Accessing %@", url);
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLCacheStorageAllowedInMemoryOnly timeoutInterval:15];
    [_connection cancel];
    [_connection release];

    [_data release];
    _data = [[NSMutableData alloc] init];

    // Keep a reference to ourself while we are alive.
    [self retain];

    _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
    [request release];
}

- (void)lookUpForShowID:(NSString *)id andExecuteBlock:(void (^)())block
{
    Block_release(_block);
    _block = Block_copy(block);
    [self lookUpForShowID:id];
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if ([_delegate respondsToSelector:@selector(movieInfoGrabber:didFailWithError:)])
        [_delegate tvShowEpisodesInfoGrabber:self didFailWithError:error];

    // Release the eventual block. This prevents ref cycle.
    if (_block) {
        Block_release(_block);
        _block = NULL;
    }

    // This balances the -retain in -lookupForTitle
    [self autorelease];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [_data appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSXMLDocument *xmlDoc = [[NSXMLDocument alloc] initWithData:_data options:0 error:nil];

    [_data release];
    _data = nil;

    //NSLog(@"%@", xmlDoc);
    NSError *error = nil;
    NSArray *nodes = [xmlDoc nodesForXPath:@"./Data/Episode" error:&error];

    if ([nodes count] > 0 ) {
        NSMutableArray *array = [NSMutableArray arrayWithCapacity:[nodes count]];
        for (NSXMLNode *node in nodes) {
            NSString *episodeId = [node stringValueForXPath:@"./id"];
            if (!episodeId)
                continue;
            NSString *title = [node stringValueForXPath:@"./EpisodeName"];
            NSNumber *seasonNumber = [node numberValueForXPath:@"./SeasonNumber"];
            NSNumber *episodeNumber = [node numberValueForXPath:@"./EpisodeNumber"];
            NSString *artworkURL = [node stringValueForXPath:@"./filename"];
            NSString *shortSummary = [node stringValueForXPath:@"./Overview"];
            [array addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                              episodeId, @"id",
                              title ?: @"", @"title",
                              shortSummary ?: @"", @"shortSummary",
                              episodeNumber, @"episodeNumber",
                              seasonNumber, @"seasonNumber",
                              [NSString stringWithFormat:TVDB_COVERS_URL, TVDB_IMAGES_HOSTNAME, artworkURL], @"artworkURL",
                              nil]];
        }
        self.results = array;
    }
    else
        self.results = nil;

    [xmlDoc release];

    if (_block) {
        _block();
        Block_release(_block);
        _block = NULL;
    }

    if ([_delegate respondsToSelector:@selector(movieInfoGrabberDidFinishGrabbing:)])
        [_delegate tvShowEpisodesInfoGrabberDidFinishGrabbing:self];

    // This balances the -retain in -lookupForTitle
    [self autorelease];
}

@end
