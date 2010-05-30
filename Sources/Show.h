//
//  Show.h
//  Lunettes
//
//  Created by Pierre d'Herbemont on 5/28/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface Show :  NSManagedObject
{
}

@property (nonatomic, retain) NSString *theTVDBID;
@property (nonatomic, retain) NSString *shortSummary;
@property (nonatomic, retain) NSString *artworkURL;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *releaseYear;
@property (nonatomic, retain) NSNumber *lastSyncDate;
@property (nonatomic, retain) NSSet *episodes;
@property (nonatomic, retain, readonly) NSSet *unreadEpisodes;

@end


@interface Show (CoreDataGeneratedAccessors)
- (void)addEpisodesObject:(NSManagedObject *)value;
- (void)removeEpisodesObject:(NSManagedObject *)value;
- (void)addEpisodes:(NSSet *)value;
- (void)removeEpisodes:(NSSet *)value;

@end

