//
//  VLCMediaLibrary.h
//  Lunettes
//
//  Created by Pierre d'Herbemont on 5/28/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "File.h"
#import "Show.h"
#import "Label.h"
#import "ShowEpisode.h"

@class VLCMedia;
@interface VLCLMediaLibrary : NSObject {
    NSManagedObjectContext *_managedObjectContext;
    NSManagedObjectModel   *_managedObjectModel;
    NSMetadataQuery *_watchedFolderQuery;
}

+ (id)sharedMediaLibrary;

- (void)savePendingChanges;

- (void)addNewLabelWithName:(NSString *)name;
- (NSManagedObject *)addSDMediaItem:(VLCMedia *)media;

- (void)addTVShowEpisodeWithInfo:(NSDictionary *)tvShowEpisodeInfo andFile:(File *)file;

- (void)media:(VLCMedia *)media hasReadPosition:(double)position;
@end
