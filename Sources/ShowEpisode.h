//
//  ShowEpisode.h
//  Lunettes
//
//  Created by Pierre d'Herbemont on 5/29/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Show;

@interface ShowEpisode :  NSManagedObject
{
}

@property (nonatomic, retain) NSNumber *unread;
@property (nonatomic, retain) NSString *theTVDBID;
@property (nonatomic, retain) NSString *shortSummary;
@property (nonatomic, retain) NSNumber *shouldBeDisplayed;
@property (nonatomic, retain) NSNumber *episodeNumber;
@property (nonatomic, retain) NSNumber *seasonNumber;
@property (nonatomic, retain) NSNumber *lastSyncDate;
@property (nonatomic, retain) NSString *artworkURL;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) Show *show;
@property (nonatomic, retain) NSSet *files;

@end


@interface ShowEpisode (CoreDataGeneratedAccessors)
- (void)addFilesObject:(NSManagedObject *)value;
- (void)removeFilesObject:(NSManagedObject *)value;
- (void)addFiles:(NSSet *)value;
- (void)removeFiles:(NSSet *)value;

@end

