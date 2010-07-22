//
//  ShowEpisode.m
//  Lunettes
//
//  Created by Pierre d'Herbemont on 5/29/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "VLCMediaLibrary.h"
#import "ShowEpisode.h"

#import "Show.h"

@interface ShowEpisode ()
@property (nonatomic, retain) NSNumber *primitiveUnread;
@end

@implementation ShowEpisode
@dynamic primitiveUnread;

@dynamic unread;


- (void)setUnread:(NSNumber *)unread
{
    [self willChangeValueForKey:@"unread"];
    [self setPrimitiveUnread:unread];
    [self didChangeValueForKey:@"unread"];
    [[[VLCLMediaLibrary sharedMediaLibrary] managedObjectContext] refreshObject:[self show] mergeChanges:YES];
    [[[VLCLMediaLibrary sharedMediaLibrary] managedObjectContext] refreshObject:self mergeChanges:YES];
}

@dynamic theTVDBID;
@dynamic shortSummary;
@dynamic shouldBeDisplayed;
@dynamic episodeNumber;
@dynamic seasonNumber;
@dynamic lastSyncDate;
@dynamic artworkURL;
@dynamic name;
@dynamic show;
@dynamic files;
@end
