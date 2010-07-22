//
//  VLCSplashScreenView.m
//  Lunettes
//
//  Created by Pierre d'Herbemont on 2/1/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "VLCSplashScreenView.h"
#import "VLCSplashScreenWindowController.h"
#import "VLCDocumentController.h"
#import "VLCMediaLibrary.h"
#import "VLCTitleDecrapifier.h"

@implementation VLCSplashScreenView
@synthesize currentArrayController=_currentArrayController;

- (NSString *)pageName
{
    return @"splash-screen";
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    if (!self)
        return nil;
    [self setup];
    return self;
}

+ (NSSet *)keyPathsForValuesAffectingMediaDiscovererArrayController
{
    return [NSSet setWithObject:@"window.windowController.mediaDiscovererArrayController"];
}

- (void)setTvShowEpisodesSortDescriptors:(NSArray *)ignored
{
}

- (NSArray *)tvShowEpisodesSortDescriptors
{
    NSSortDescriptor *season = [[[NSSortDescriptor alloc]
                                initWithKey:@"seasonNumber"
                                ascending:NO
                                selector:@selector(compare:)] autorelease];
    NSSortDescriptor *episode = [[[NSSortDescriptor alloc]
                                 initWithKey:@"episodeNumber"
                                 ascending:NO
                                 selector:@selector(compare:)] autorelease];
    return [NSArray arrayWithObjects:season, episode, nil];
}

- (NSPredicate *)predicateThatFiltersShowEpisodeWithoutFile
{
    return [NSPredicate predicateWithFormat:@"files.@count > 0"];
}

- (NSDocumentController *)documentController
{
    DIRECTLY_RETURN_OBJECT_TO_JS([NSDocumentController sharedDocumentController]);
}

- (NSArrayController *)mediaDiscovererArrayController
{
    DIRECTLY_RETURN_OBJECT_TO_JS([[[self window] windowController] mediaDiscovererArrayController]);
}

- (NSArrayController *)clipsArrayController
{
    DIRECTLY_RETURN_OBJECT_TO_JS([[[self window] windowController] clipsArrayController]);
}

- (NSArrayController *)moviesArrayController
{
    DIRECTLY_RETURN_OBJECT_TO_JS([[[self window] windowController] moviesArrayController]);
}

- (NSArrayController *)tvShowsArrayController
{
    DIRECTLY_RETURN_OBJECT_TO_JS([[[self window] windowController] tvShowsArrayController]);
}

- (NSArrayController *)tvShowEpisodesArrayController
{
    DIRECTLY_RETURN_OBJECT_TO_JS([[[self window] windowController] tvShowEpisodesArrayController]);
}

- (NSArrayController *)labelsArrayController
{
    DIRECTLY_RETURN_OBJECT_TO_JS([[[self window] windowController] labelsArrayController]);
}

- (void)didFinishLoadForFrame:(WebFrame *)frame
{
    [super didFinishLoadForFrame:frame];

    // See the comment in -loadArrayControllers definition.
    // We do it in the next run loop run to make sure we'll still properly
    // display the view first.
    [[[self window] windowController] performSelector:@selector(loadArrayControllers) withObject:nil afterDelay:0];
}

- (void)playCocoaObject:(WebScriptObject *)object
{
    FROM_JS();

    id representedObject = [object valueForKey:@"backendObject"];
    if ([representedObject isKindOfClass:[NSManagedObject class]]) {
        NSManagedObject *mo = representedObject;
        if ([[[mo entity] name] isEqualToString:@"ShowEpisode"]) {
            NSSet *files = [representedObject valueForKey:@"files"];
            if ([files count] > 1) {
                VLCMediaList *mediaList = [[[VLCMediaList alloc] init] autorelease];
                for (id file in files) {
                    NSURL *url = [NSURL URLWithString:[file valueForKey:@"url"]];
                    [mediaList addMedia:[VLCMedia mediaWithURL:url]];

                }
                [[VLCDocumentController sharedDocumentController] makeDocumentWithMediaList:mediaList andName:[representedObject valueForKey:@"name"]];
                [[[self window] windowController] close];
                return;
            }
            representedObject = [files anyObject];
        }
    }
    NSString *stringURL = [representedObject valueForKey:@"url"];
    NSURL *url = [NSURL URLWithString:stringURL];
    VLCAssert(url, @"Invalid string in DB!");
    double position = [[representedObject valueForKey:@"lastPosition"] doubleValue];
    [[VLCDocumentController sharedDocumentController] makeDocumentWithURL:url andStartingPosition:position];
    [[[self window] windowController] close];
    RETURN_NOTHING_TO_JS();
}

- (void)playMediaDiscoverer:(WebScriptObject *)mdObject withMedia:(WebScriptObject *)mediaObject
{
    FROM_JS();
    VLCMedia *media = [mediaObject valueForKey:@"backendObject"];
    VLCMediaDiscoverer *mediaDiscoverer = [mdObject valueForKey:@"backendObject"];
    [[VLCDocumentController sharedDocumentController] makeDocumentWithMediaDiscoverer:mediaDiscoverer andMediaToPlay:media];
    [[[self window] windowController] close];
    RETURN_NOTHING_TO_JS();
}

- (void)playArrayControllerList:(WebScriptObject *)arrayController withMedia:(WebScriptObject *)webMedia
{
    FROM_JS();
    NSArray *array = [[arrayController valueForKey:@"backendObject"] arrangedObjects];
    NSManagedObject *managedMediaToPlay = [webMedia valueForKey:@"backendObject"];
    VLCMediaList *list = [[VLCMediaList alloc] init];
    VLCMedia *mediaToPlay = nil;
    for (NSManagedObject *managedMedia in array) {
        VLCMedia *media = [VLCMedia mediaWithURL:[NSURL URLWithString:[managedMedia valueForKey:@"url"]]];
        [media setValue:[managedMedia valueForKey:@"title"] forMeta:VLCMetaInformationTitle];
        [list addMedia:media];
        if (managedMedia == managedMediaToPlay)
            mediaToPlay = media;
    }
    [[VLCDocumentController sharedDocumentController] makeDocumentWithMediaList:list andName:@"Label" andMediaToPlay:mediaToPlay];
    [list release];
    [[[self window] windowController] close];
    RETURN_NOTHING_TO_JS();
}

- (void)addNewLabel
{
    FROM_JS();
    NSString *name = @"Undefined";
    [[VLCLMediaLibrary sharedMediaLibrary] addNewLabelWithName:name];
    RETURN_NOTHING_TO_JS();
}

- (void)setLabel:(WebScriptObject *)weblabel forMedia:(WebScriptObject *)webmedia
{
    FROM_JS();
    NSManagedObject *label = [weblabel valueForKey:@"backendObject"];
    id media = [webmedia valueForKey:@"backendObject"];
    NSManagedObject *managedMedia = media;
    if ([media isKindOfClass:[VLCMedia class]])
        managedMedia = [[VLCLMediaLibrary sharedMediaLibrary] addSDMediaItem:media];
    [[label mutableSetValueForKey:@"files"] addObject:managedMedia];
    RETURN_NOTHING_TO_JS();
}

- (void)removeLabel:(WebScriptObject *)weblabel forMedia:(WebScriptObject *)webmedia
{
    FROM_JS();
    NSManagedObject *label = [weblabel valueForKey:@"backendObject"];
    NSManagedObject *media = [webmedia valueForKey:@"backendObject"];
    NSMutableSet *set = [media mutableSetValueForKey:@"labels"];
    [set removeObject:label];
    RETURN_NOTHING_TO_JS();
}


- (BOOL)remove:(WebScriptObject *)webobject
{
    FROM_JS();
    id object = [webobject valueForKey:@"backendObject"];
    NSString *name;
    BOOL isShowEpisode = [object isKindOfClass:[ShowEpisode class]];
    if (isShowEpisode)
        name = [object valueForKey:@"name"];
    else
        name = [object valueForKey:@"title"];

    NSAlert *alert = [NSAlert alertWithMessageText:@"Remove an item"
                                     defaultButton:@"Cancel"
                                   alternateButton:@"Remove"
                                       otherButton:nil
                            informativeTextWithFormat: @"Do you really want to remove the item \"%@\"?", name];
    NSUInteger btn = [alert runModal];
    if (btn != 0)
        return NO;
    if (isShowEpisode) {
        [object setValue:[NSNumber numberWithBool:NO] forKey:@"shouldBeDisplayed"];
    } else {
        [object setValue:@"hidden" forKey:@"type"];
        [object setValue:[NSSet set] forKey:@"labels"];
    }
    RETURN_VALUE_TO_JS(YES);
}

- (void)setType:(NSString *)type forFile:(WebScriptObject *)webfile
{
    FROM_JS();
    File *file = [webfile valueForKey:@"backendObject"];
    [file setValue:type forKey:@"type"];
    if ([type isEqualToString:@"tvShowEpisode"]) {
        NSDictionary *dictionary = [VLCTitleDecrapifier tvShowEpisodeInfoFromString:file.title];
        [[VLCLMediaLibrary sharedMediaLibrary] addTVShowEpisodeWithInfo:dictionary andFile:file];
    }

    RETURN_NOTHING_TO_JS();
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)sel
{
    if (sel == @selector(playMediaDiscoverer:withMedia:))
        return NO;
    if (sel == @selector(playCocoaObject:))
        return NO;
    if (sel == @selector(addNewLabel))
        return NO;
    if (sel == @selector(remove:))
        return NO;
    if (sel == @selector(setLabel:forMedia:))
        return NO;
    if (sel == @selector(removeLabel:forMedia:))
        return NO;
    if (sel == @selector(setType:forFile:))
        return NO;
    if (sel == @selector(playArrayControllerList:withMedia:))
        return NO;
    return [super isSelectorExcludedFromWebScript:sel];
}

+ (NSString *)webScriptNameForSelector:(SEL)sel
{
    if (sel == @selector(playMediaDiscoverer:withMedia:))
        return @"playMediaDiscovererWithMedia";
    if (sel == @selector(playCocoaObject:))
        return @"playCocoaObject";
    if (sel == @selector(remove:))
        return @"remove";
    if (sel == @selector(setType:forFile:))
        return @"setTypeForFile";
    if (sel == @selector(setLabel:forMedia:))
        return @"setLabelForMedia";
    if (sel == @selector(playArrayControllerList:withMedia:))
        return @"playArrayControllerListWithMedia";
    if (sel == @selector(removeLabel:forMedia:))
        return @"removeLabelForMedia";
    return [super webScriptNameForSelector:sel];
}

- (void)selectAll:(id)sender
{
    NSArrayController *controller = [[VLCDocumentController sharedDocumentController] currentArrayController];
    [controller setSelectedObjects:[controller arrangedObjects]];
}
@end
