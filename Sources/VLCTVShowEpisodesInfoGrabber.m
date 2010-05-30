//
//  VLCTVShowEpisodesInfoGrabber.m
//  Lunettes
//
//  Created by Pierre d'Herbemont on 5/24/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "VLCTVShowEpisodesInfoGrabber.h"
#import "NSXMLNode_Additions.h"
#import "VLCURLConnection.h"

#import "TheTVDBGrabber.h"

@interface VLCTVShowEpisodesInfoGrabber ()
@property (readwrite, retain) NSDictionary *results;
@property (readwrite, retain) NSArray *episodesResults;

- (void)didReceiveData:(NSData *)data;
@end

@implementation VLCTVShowEpisodesInfoGrabber
@synthesize delegate=_delegate;
@synthesize episodesResults=_episodesResults;
@synthesize results=_results;
- (void)dealloc
{
    [_connection release];
    [_results release];
    [_episodesResults release];
    if (_block)
        Block_release(_block);
    [super dealloc];
}

- (void)lookUpForShowID:(NSString *)showId
{
    [_connection cancel];
    [_connection release];

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:TVDB_QUERY_EPISODE_INFO, TVDB_HOSTNAME, TVDB_API_KEY, showId, TVDB_DEFAULT_LANGUAGE]];

    // Balanced below
    [self retain];

    _connection = [[VLCURLConnection runConnectionWithURL:url andBlock:^(VLCURLConnection *connection, NSError * error) {
        if (error) {
            [_connection release];
            _connection = nil;
            [self autorelease];
            return;
        }
        [self didReceiveData:connection.data];
        [self autorelease];
    }] retain];
}

- (void)lookUpForShowID:(NSString *)id andExecuteBlock:(void (^)())block
{
    Block_release(_block);
    _block = Block_copy(block);
    [self lookUpForShowID:id];
}

- (void)didReceiveData:(NSData *)data
{
    NSXMLDocument *xmlDoc = [[NSXMLDocument alloc] initWithData:data options:0 error:nil];

    NSError *error = nil;
    NSArray *nodesSerie = [xmlDoc nodesForXPath:@"./Data/Series" error:&error];
    NSArray *nodesEpisode = [xmlDoc nodesForXPath:@"./Data/Episode" error:&error];


    NSString *serieArtworkURL = nil;
    if ([nodesSerie count] == 1) {
        NSXMLNode *node = [nodesSerie objectAtIndex:0];
        serieArtworkURL = [node stringValueForXPath:@"./poster"];
    }

    if ([nodesEpisode count] > 0 ) {
        NSMutableArray *array = [NSMutableArray arrayWithCapacity:[nodesEpisode count]];

        for (NSXMLNode *node in nodesEpisode) {
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
        self.episodesResults = array;
        self.results = [NSDictionary dictionaryWithObjectsAndKeys:
                        [NSString stringWithFormat:TVDB_COVERS_URL, TVDB_IMAGES_HOSTNAME, serieArtworkURL], @"serieArtworkURL", nil];
    }
    else {
        self.episodesResults = nil;
        self.results = nil;

    }

    [xmlDoc release];

    if (_block) {
        _block();
        Block_release(_block);
        _block = NULL;
    }

    if ([_delegate respondsToSelector:@selector(movieInfoGrabberDidFinishGrabbing:)])
        [_delegate tvShowEpisodesInfoGrabberDidFinishGrabbing:self];
}

@end
