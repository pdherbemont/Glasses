//
//  Show.m
//  Lunettes
//
//  Created by Pierre d'Herbemont on 5/28/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Show.h"


@implementation Show

@dynamic theTVDBID;
@dynamic shortSummary;
@dynamic artworkURL;
@dynamic name;
@dynamic lastSyncDate;
@dynamic releaseYear;
@dynamic episodes;
@dynamic unreadEpisodes;

//- (NSSet *)unreadEpisodes
//{
//    NSSet *episodes = [self episodes];
//    NSMutableSet *set = [NSMutableSet set];
//    for(id episode in set) {
//        NSSet *files = [episode valueForKey:@"files"];
//        for(id file in files) {
//            if ([[file valueForKey:@"unread"] boolValue]) {
//                [set addObject:episode];
//                break;
//            }
//        }
//    }
//    return set;
//}
@end
