//
//  VLCMediaLibrary.m
//  Lunettes
//
//  Created by Pierre d'Herbemont on 5/28/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <VLCKit/VLCKit.h>
#import "VLCMovieInfoGrabber.h"
#import "VLCTVShowInfoGrabber.h"
#import "VLCTitleDecrapifier.h"
#import "VLCMovieInfoGrabberWindowController.h"
#import "VLCTVShowInfoGrabberWindowController.h"
#import "VLCTVShowEpisodesInfoGrabber.h"

#import "VLCMediaLibrary.h"

#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
@interface VLCLMediaLibrary () <NSMetadataQueryDelegate>
#else
@interface VLCLMediaLibrary ()
#endif

- (void)setupFolderWatch;
- (void)startWatchingFolders;
- (void)scanFolderSettingDidChange;
- (NSManagedObjectContext *)managedObjectContext;

@end

@implementation VLCLMediaLibrary
+ (id)sharedMediaLibrary
{
    static id sharedMediaLibrary = nil;
    if (!sharedMediaLibrary)
        sharedMediaLibrary = [[[self class] alloc] init];
    return sharedMediaLibrary;
}

- (NSFetchRequest *)fetchRequestForEntity:(NSString *)entity
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSManagedObjectContext *moc = [self managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:entity inManagedObjectContext:moc];
    [request setEntity:entityDescription];
    return [request autorelease];
}

- (id)createObjectForEntity:(NSString *)entity
{
    NSManagedObjectContext *moc = [self managedObjectContext];
    return [NSEntityDescription insertNewObjectForEntityForName:entity inManagedObjectContext:moc];
}

#pragma mark -
#pragma mark Media Library
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel)
        return _managedObjectModel;
    _managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];
    return _managedObjectModel;
}

- (NSString *)applicationSupportFolder
{
    NSString *applicationSupportFolder = nil;
    FSRef foundRef;
    OSErr err = FSFindFolder(kUserDomain, kApplicationSupportFolderType, kDontCreateFolder, &foundRef);
    VLCAssert(err == noErr, @"Can't find application support folder");

    unsigned char path[1024];
    FSRefMakePath(&foundRef, path, sizeof(path));
    applicationSupportFolder = [NSString stringWithUTF8String:(char *)path];
    applicationSupportFolder = [applicationSupportFolder stringByAppendingPathComponent:@"org.videolan.Lunettes"];

    return applicationSupportFolder;
}

- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext)
        return _managedObjectContext;

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *applicationSupportFolder = [self applicationSupportFolder];
    if (![fileManager fileExistsAtPath:applicationSupportFolder isDirectory:NULL])
        [fileManager createDirectoryAtPath:applicationSupportFolder withIntermediateDirectories:YES attributes:nil error:nil];

    NSURL *url = [NSURL fileURLWithPath: [applicationSupportFolder stringByAppendingPathComponent: @"MediaLibrary.sqlite"]];
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];

    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];

    NSError *error;
    if ([coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:options error:&error]) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator: coordinator];
    } else {
        // FIXME: Deal with versioning
        NSInteger ret = NSRunAlertPanel(@"Error", @"The Media Library you have on your disk is not compatible with the one Lunettes can read. Do you want to create a new one?", @"No", @"Yes", nil);
        if (ret == NSOKButton)
            [NSApp terminate:nil];
        [fileManager removeItemAtURL:url error:nil];
        NSRunInformationalAlertPanel(@"Relaunch Lunettes now", @"We need to relaunch Lunettes to proceed", @"OK", nil, nil);
        [NSApp terminate:nil];
    }
    [coordinator release];
    [_managedObjectContext setUndoManager:nil];
    [_managedObjectContext addObserver:self forKeyPath:@"hasChanges" options:NSKeyValueObservingOptionInitial context:nil];
    return _managedObjectContext;
}

- (void)savePendingChanges
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(savePendingChanges) object:nil];
    [[self managedObjectContext] save:nil];

#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    NSProcessInfo *process = [NSProcessInfo processInfo];
    if ([process respondsToSelector:@selector(enableSuddenTermination)])
        [process enableSuddenTermination];
#endif
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(id)context
{
    if ([keyPath isEqualToString:@"hasChanges"] && object == _managedObjectContext) {
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
        NSProcessInfo *process = [NSProcessInfo processInfo];
        if ([process respondsToSelector:@selector(disableSuddenTermination)])
            [process disableSuddenTermination];
#endif

        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(savePendingChanges) object:nil];
        [self performSelector:@selector(savePendingChanges) withObject:nil afterDelay:1.];
        return;
    }
    if ([context isKindOfClass:[NSValue class]]) {
        // Dispatch selector
        // This is useful for NSUserDefaults observing.
        [self performSelector:[context pointerValue]];
        return;
    }
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

/**
 * Remember a movie that wasn't finished
 */
- (void)media:(VLCMedia *)media hasReadPosition:(double)position
{
    VLCAssert(![[NSUserDefaults standardUserDefaults] boolForKey:kDontRememberUnfinishedMovies], @"kDontRememberUnfinishedMovies is here");

    File *movie = nil;

    // Try to find an entry for that media
    // FIXME - cache the result?
    NSFetchRequest *request = [self fetchRequestForEntity:@"File"];
    [request setFetchLimit:1];

    [request setPredicate:[NSPredicate predicateWithFormat:@"url LIKE[c] %@", [media.url description]]];

    NSArray *results = [[self managedObjectContext] executeFetchRequest:request error:nil];

    if ([results count] > 0)
        movie = [results objectAtIndex:0];

    // Remove/don't save if we are nearly done or if the length is less 2:30 secs.
    if ([[media length] intValue] < 150000)
        return;

    NSNumber *no = [NSNumber numberWithBool:NO];
    NSNumber *yes = [NSNumber numberWithBool:YES];

    if (position > 0.95) {
        if (movie) {
            movie.lastPosition = [NSNumber numberWithInt:0];
            movie.unread = no;
            movie.currentlyWatching = no;
            // Increment the play count
            NSUInteger count = [movie.playCount unsignedIntValue];
            movie.playCount = [NSNumber numberWithUnsignedInt:count + 1];
        }
        return;
    }

    NSNumber *oldposition = movie.lastPosition;
    if (oldposition && position < [oldposition doubleValue])
        return;
    if (!movie) {
        movie = [self createObjectForEntity:@"File"];
        movie.url = [media.url description];
    }

    // Yes, this is a negative number. VLCTime nicely display negative time
    // with "XX minutes remaining". And we are using this facility.
    double remainingTime = [[[media length] numberValue] doubleValue] * (position - 1);

    movie.currentlyWatching = yes;
    movie.unread = no;
    movie.lastPosition = [NSNumber numberWithDouble:position];
    movie.remainingTime = [NSNumber numberWithDouble:remainingTime];
}

#pragma mark Media Library: Path Watcher

- (void)addNewLabelWithName:(NSString *)name
{
    Label *label = [self createObjectForEntity:@"Label"];
    label.name = name;
}

- (NSManagedObject *)addSDMediaItem:(VLCMedia *)media
{
    NSURL *url = [media url];
    NSString *title = [[media metaDictionary] objectForKey:VLCMetaInformationTitle];

    File *movie = [self createObjectForEntity:@"File"];
    movie.url = [url description];
    NSNumber *no = [NSNumber numberWithBool:NO];
    movie.currentlyWatching = no;
    movie.lastPosition = [NSNumber numberWithDouble:0];
    movie.remainingTime = [NSNumber numberWithDouble:0];
    movie.unread = no;
    movie.type = @"sd";
    movie.title = title;

    return movie;
}

/**
 * TV Show Episodes
 */
- (Show *)tvShowWithName:(NSString *)name
{
    NSFetchRequest *request = [self fetchRequestForEntity:@"Show"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"name LIKE %@", name]];

    NSArray *dbResults = [[self managedObjectContext] executeFetchRequest:request error:nil];

    if ([dbResults count] <= 0)
        return nil;

    return [dbResults objectAtIndex:0];
}

- (ShowEpisode *)showEpisodeWithShow:(id)show episodeNumber:(NSNumber *)episodeNumber seasonNumber:(NSNumber *)seasonNumber
{
    NSMutableSet *episodes = [show mutableSetValueForKey:@"episodes"];
    ShowEpisode *episode = nil;
    if (seasonNumber && episodeNumber) {
        for (ShowEpisode *episodeIter in episodes) {
            if ([episodeIter.seasonNumber intValue] == [seasonNumber intValue] &&
                [episodeIter.episodeNumber intValue] == [episodeNumber intValue]) {
                episode = episodeIter;
                break;
            }
        }
    }
    if (!episode) {
        episode = [self createObjectForEntity:@"ShowEpisode"];
        episode.episodeNumber = episodeNumber;
        episode.seasonNumber = seasonNumber;
        [episodes addObject:episode];
    }
    return episode;
}

- (ShowEpisode *)showEpisodeWithShowName:(NSString *)showName episodeNumber:(NSNumber *)episodeNumber seasonNumber:(NSNumber *)seasonNumber wasInserted:(BOOL *)wasInserted show:(Show **)returnedShow
{
    Show *show = [self tvShowWithName:showName];
    *wasInserted = NO;
    if (!show) {
        *wasInserted = YES;
        show = [self createObjectForEntity:@"Show"];
        show.name = showName;
    }
    *returnedShow = show;
    return [self showEpisodeWithShow:show episodeNumber:episodeNumber seasonNumber:seasonNumber];
}

- (void)fetchMetaDataForShow:(Show *)show
{
    // First fetch the serverTime, so that we can update each entry.

    [VLCTVShowInfoGrabber fetchServerTimeAndExecuteBlock:^(NSNumber *serverDate) {

        [[NSUserDefaults standardUserDefaults] setInteger:[serverDate integerValue] forKey:kLastTVDBUpdateServerTime];

        // First fetch the Show ID
        VLCTVShowInfoGrabber *grabber = [[[VLCTVShowInfoGrabber alloc] init] autorelease];
        [grabber lookUpForTitle:show.name andExecuteBlock:^{
            NSArray *results = grabber.results;
            if ([results count] > 0) {
                NSDictionary *result = [results objectAtIndex:0];
                NSString *showId = [result objectForKey:@"id"];

                show.theTVDBID = showId;
                show.name = [result objectForKey:@"title"];
                show.shortSummary = [result objectForKey:@"shortSummary"];
                show.releaseYear = [result objectForKey:@"releaseYear"];

                // Fetch episode info
                VLCTVShowEpisodesInfoGrabber *grabber = [[[VLCTVShowEpisodesInfoGrabber alloc] init] autorelease];
                [grabber lookUpForShowID:showId andExecuteBlock:^{
                    NSArray *results = grabber.episodesResults;
                    [show setValue:[grabber.results objectForKey:@"serieArtworkURL"] forKey:@"artworkURL"];
                    for (id result in results) {
                        if ([[result objectForKey:@"serie"] boolValue]) {
                            continue;
                        }
                        ShowEpisode *showEpisode = [self showEpisodeWithShow:show episodeNumber:[result objectForKey:@"episodeNumber"] seasonNumber:[result objectForKey:@"seasonNumber"]];
                        showEpisode.name = [result objectForKey:@"title"];
                        showEpisode.theTVDBID = [result objectForKey:@"id"];
                        showEpisode.shortSummary = [result objectForKey:@"shortSummary"];
                        showEpisode.artworkURL = [result objectForKey:@"artworkURL"];
                        showEpisode.lastSyncDate = serverDate;
                    }
                    show.lastSyncDate = serverDate;
                }];
            }
            else {
                // Not found.
                show.lastSyncDate = serverDate;
            }

        }];
    }];
}

- (void)addTVShowEpisodeWithInfo:(NSDictionary *)tvShowEpisodeInfo andFile:(File *)file
{
    file.type = @"tvShowEpisode";

    NSNumber *seasonNumber = [tvShowEpisodeInfo objectForKey:@"season"];
    NSNumber *episodeNumber = [tvShowEpisodeInfo objectForKey:@"episode"];
    NSString *tvShowName = [tvShowEpisodeInfo objectForKey:@"tvShowName"];
    BOOL hasNoTvShow = NO;
    if (!tvShowName) {
        tvShowName = @"Untitled TV Show";
        hasNoTvShow = YES;
    }
    BOOL wasInserted = NO;
    Show *show = nil;
    ShowEpisode *episode = [self showEpisodeWithShowName:tvShowName episodeNumber:episodeNumber seasonNumber:seasonNumber wasInserted:&wasInserted show:&show];

    if (wasInserted && !hasNoTvShow) {
        show.name = tvShowName;
        [self fetchMetaDataForShow:show];
    }

    if (hasNoTvShow)
        episode.name = file.title;
    file.seasonNumber = seasonNumber;
    file.episodeNumber = episodeNumber;
    episode.shouldBeDisplayed = [NSNumber numberWithBool:YES];

    [episode addFilesObject:file];
}


/**
 * File auto detection
 */

- (void)fetchMetaDataForFile:(File *)file
{
    NSNumber *yes = [NSNumber numberWithBool:YES];

    NSDictionary *tvShowEpisodeInfo = [VLCTitleDecrapifier tvShowEpisodeInfoFromString:file.title];
    if (tvShowEpisodeInfo) {
        [self addTVShowEpisodeWithInfo:tvShowEpisodeInfo andFile:file];
        file.hasFetchedInfo = yes;
        return;
    }

    // Go online and fetch info.
    VLCMovieInfoGrabber *grabber = [[[VLCMovieInfoGrabber alloc] init] autorelease];
    [grabber lookUpForTitle:file.title andExecuteBlock:^(NSError *err){
        if (err)
            return;

        NSArray *results = grabber.results;
        if ([results count] > 0) {
            NSDictionary *result = [results objectAtIndex:0];
            file.artworkURL = [result objectForKey:@"artworkURL"];
            file.title = [result objectForKey:@"title"];
            file.shortSummary = [result objectForKey:@"shortSummary"];
            file.releaseYear = [result objectForKey:@"releaseYear"];
        }
        file.hasFetchedInfo = yes;
    }];
}

- (void)addMetadataItem:(NSMetadataItem *)result
{
    NSString *url = [NSURL fileURLWithPath:[result valueForAttribute:@"kMDItemPath"]];
    NSString *title = [result valueForAttribute:@"kMDItemDisplayName"];
    NSDate *openedDate = [result valueForAttribute:@"kMDItemLastUsedDate"];
    NSDate *modifiedDate = [result valueForAttribute:@"kMDItemFSContentChangeDate"];
    NSNumber *size = [result valueForAttribute:@"kMDItemFSSize"];

    File *file = [self createObjectForEntity:@"File"];
    file.url = [url description];

    // Yes, this is a negative number. VLCTime nicely display negative time
    // with "XX minutes remaining". And we are using this facility.

    NSNumber *no = [NSNumber numberWithBool:NO];
    NSNumber *yes = [NSNumber numberWithBool:YES];

    file.currentlyWatching = no;
    file.lastPosition = [NSNumber numberWithDouble:0];
    file.remainingTime = [NSNumber numberWithDouble:0];
    file.unread = yes;

    if ([openedDate isGreaterThan:modifiedDate]) {
        file.playCount = [NSNumber numberWithDouble:1];
        file.unread = no;
    }
    file.title = [VLCTitleDecrapifier decrapify:[title stringByDeletingPathExtension]];

    if ([size longLongValue] < 150000000) /* 150 MB */
        file.type = @"clip";
    else
        file.type = @"movie";

    [self fetchMetaDataForFile:file];
}

- (void)addMetadataItems:(NSArray *)metaDataItems
{
    NSUInteger count = [metaDataItems count];
    NSMutableArray *fetchPredicates = [NSMutableArray arrayWithCapacity:count];
    NSMutableDictionary *urlToObject = [NSMutableDictionary dictionaryWithCapacity:count];

    // Prepare a fetch request for all items
    for (NSMetadataItem *metaDataItem in metaDataItems) {
        NSString *path = [metaDataItem valueForAttribute:@"kMDItemPath"];

        NSURL *url = [NSURL fileURLWithPath:path];
        NSString *urlDescription = [url description];
        [fetchPredicates addObject:[NSPredicate predicateWithFormat:@"url == %@", urlDescription]];
        [urlToObject setObject:metaDataItem forKey:urlDescription];
    }

    NSFetchRequest *request = [self fetchRequestForEntity:@"File"];

    [request setPredicate:[NSCompoundPredicate orPredicateWithSubpredicates:fetchPredicates]];

    NSLog(@"Fetching");
    NSArray *dbResults = [[self managedObjectContext] executeFetchRequest:request error:nil];
    NSLog(@"Done");

    NSMutableArray *metaDataItemsToAdd = [NSMutableArray arrayWithArray:metaDataItems];

    // Remove objects that are already in db.
    for (NSManagedObjectContext *dbResult in dbResults) {
        NSString *url = [dbResult valueForKey:@"url"];
        [metaDataItemsToAdd removeObject:[urlToObject objectForKey:url]];
    }

    // Add only the newly added items
    for (NSMetadataItem *metaDataItem in metaDataItemsToAdd) {
        [self addMetadataItem:metaDataItem];
    }
}

- (void)gotFirstResults:(NSNotification *)notification
{
    NSLog(@"Got First results");
    NSMetadataQuery *query = [notification object];
    NSArray *array = [query results];
    [self addMetadataItems:array];
    NSLog(@"Adding done");
}

- (void)gotAdditionalResults:(NSNotification *)notification
{
    NSLog(@"Got Additional results");
    NSMetadataQuery *query = [notification object];
    NSArray *array = [query results];
    [self addMetadataItems:array];
    NSLog(@"Adding done");
}

- (void)startUpdateDB
{
    // FIXME
    NSFetchRequest *request = [self fetchRequestForEntity:@"File"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"hasFetchedInfo == 0"]];
    NSArray *results = [[self managedObjectContext] executeFetchRequest:request error:nil];

    for (File *file in results)
        [self fetchMetaDataForFile:file];

    request = [self fetchRequestForEntity:@"Show"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"lastSyncDate == 0"]];
    results = [[self managedObjectContext] executeFetchRequest:request error:nil];

    for (Show *show in results)
        [self fetchMetaDataForShow:show];

    NSInteger lastServerTime = [[NSUserDefaults standardUserDefaults] integerForKey:kLastTVDBUpdateServerTime];
    [VLCTVShowInfoGrabber fetchUpdatesSinceServerTime:[NSNumber numberWithInteger:lastServerTime] andExecuteBlock:^(NSArray *updates){
        NSFetchRequest *request = [self fetchRequestForEntity:@"Show"];
        [request setPredicate:[NSComparisonPredicate predicateWithLeftExpression:[NSExpression expressionForKeyPath:@"theTVDBID"] rightExpression:[NSExpression expressionForConstantValue:updates] modifier:NSDirectPredicateModifier type:NSInPredicateOperatorType options:0]];
        NSArray *results = [[self managedObjectContext] executeFetchRequest:request error:nil];
        for (Show *show in results)
            [self fetchMetaDataForShow:show];
    }];

    /* Update every hour - FIXME: Preferences key */
    [self performSelector:@selector(startUpdateDB) withObject:nil afterDelay:60 * 60];
}

- (void)setupFolderWatch
{
    // Watch for modification on User Defaults.
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    static NSValue *value = nil;
    if (!value)
        value = [[NSValue valueWithPointer:@selector(scanFolderSettingDidChange)] retain];
    [defaults addObserver:self forKeyPath:kDisableFolderScanning options:0 context:value];
    [defaults addObserver:self forKeyPath:kScannedFolders options:0 context:value];

    [self startWatchingFolders];

    // After 10 seconds start to update TV Shows.
    // FIXME - Enqueue this after folder whatch.
    [self performSelector:@selector(startUpdateDB) withObject:nil afterDelay:0];
}

- (void)startWatchingFolders
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if ([defaults boolForKey:kDisableFolderScanning])
        return;
    if (_watchedFolderQuery)
        return;
    _watchedFolderQuery = [[NSMetadataQuery alloc] init];
    NSArray *folders = [defaults arrayForKey:kScannedFolders];
    [_watchedFolderQuery setSearchScopes:folders];
    [_watchedFolderQuery setPredicate:[NSPredicate predicateWithFormat:@"kMDItemContentTypeTree == 'public.movie'"]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gotFirstResults:) name:NSMetadataQueryDidFinishGatheringNotification object:_watchedFolderQuery];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gotAdditionalResults:) name:NSMetadataQueryDidUpdateNotification object:_watchedFolderQuery];
    [_watchedFolderQuery startQuery];
}

- (void)scanFolderSettingDidChange
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:kDisableFolderScanning]) {
        if (_watchedFolderQuery) {
            [_watchedFolderQuery stopQuery];
            [_watchedFolderQuery release];
            _watchedFolderQuery = nil;
        }
        return;
    }
    if (!_watchedFolderQuery)
        return [self startWatchingFolders];

    NSArray *folders = [defaults arrayForKey:kScannedFolders];
    [_watchedFolderQuery setSearchScopes:folders];
}

@end
