/*****************************************************************************
 * Copyright (C) 2009 the VideoLAN team
 *
 * Authors: Pierre d'Herbemont
 *          Felix Paul Kühne
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/

#import "VLCSplashScreenWindowController.h"
#import "VLCDocumentController.h"
#import "VLCDVDDiscoverer.h"

#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
@interface VLCSplashScreenWindowController () <NSWindowDelegate>
@end
#endif

#if !ENABLE_EXTENDED_SPLASH_SCREEN
@interface VLCSplashScreenWindowController ()
@property (assign, readwrite) BOOL hasSelection;
@end
#endif

@implementation VLCSplashScreenWindowController
#if !ENABLE_EXTENDED_SPLASH_SCREEN
@synthesize hasSelection=_hasSelection;
#endif

@synthesize moviesArrayController=_moviesArrayController;
@synthesize labelsArrayController=_labelsArrayController;
@synthesize clipsArrayController=_clipsArrayController;
@synthesize tvShowsArrayController=_tvShowsArrayController;
@synthesize tvShowEpisodesArrayController=_tvShowEpisodesArrayController;
@synthesize mediaDiscovererArrayController=_mediaDiscovererArrayController;

- (void)dealloc
{
#if ENABLE_EXTENDED_SPLASH_SCREEN
    [_mediaDiscovererArrayController release];
#endif
    [super dealloc];
}

- (NSArray *)sortDescriptor
{
    NSSortDescriptor *title = [[[NSSortDescriptor alloc]
                                initWithKey:@"title"
                                ascending:YES
                                selector:@selector(localizedCaseInsensitiveCompare:)] autorelease];
    NSSortDescriptor *unread = [[[NSSortDescriptor alloc]
                                 initWithKey:@"unread"
                                 ascending:NO
                                 selector:@selector(compare:)] autorelease];
    NSSortDescriptor *lastPosition = [[[NSSortDescriptor alloc]
                                       initWithKey:@"lastPosition"
                                       ascending:NO
                                       selector:@selector(compare:)] autorelease];
    return [NSArray arrayWithObjects:lastPosition, unread, title, nil];
}

- (NSArray *)sortDescriptorsForTVShows
{
    NSSortDescriptor *unread = [[[NSSortDescriptor alloc]
                                 initWithKey:@"unreadEpisodes.@count"
                                 ascending:NO
                                 selector:@selector(compare:)] autorelease];
    NSSortDescriptor *name = [[[NSSortDescriptor alloc]
                                initWithKey:@"name"
                                ascending:YES
                                selector:@selector(localizedCaseInsensitiveCompare:)] autorelease];
    return [NSArray arrayWithObjects:unread, name, nil];
}

- (NSArray *)availableMediaDiscoverer
{
    if( !availableMediaDiscoverer )
    {
        availableMediaDiscoverer = [[NSArray arrayWithObjects:
                                     [[[VLCMediaDiscoverer alloc] initWithName:@"sap"] autorelease],
                                     [[[VLCMediaDiscoverer alloc] initWithName:@"freebox"] autorelease],
                                     [[[VLCDVDDiscoverer alloc] init] autorelease],nil] retain];
    }
    return availableMediaDiscoverer;

}

- (NSString *)windowNibName
{
#if ENABLE_EXTENDED_SPLASH_SCREEN
    return @"NewSplashScreenWindow";
#else
    return @"SplashScreenWindow";
#endif
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    NSWindow *window = [self window];

    [window center];
    [window setDelegate:self];
#if !ENABLE_EXTENDED_SPLASH_SCREEN
    VLCAssert(_mediaDiscoverCollection, @"There is no collectionView");
    VLCAssert(_unfinishedItemsCollection, @"There is no collectionView");
    [_unfinishedItemsCollection registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
#endif
}

- (void)windowDidClose:(NSNotification *)notification
{
#if !ENABLE_EXTENDED_SPLASH_SCREEN
    [_unfinishedItemsCollection setDelegate:nil];
    [_mediaDiscoverCollection setDelegate:nil];
#endif
    [[VLCDocumentController sharedDocumentController] closeSplashScreen];
}

/**
 * This methods is being used by the bindings of the services view.
 */
- (VLCDocumentController *)documentController
{
    return [VLCDocumentController sharedDocumentController];
}

#if !ENABLE_EXTENDED_SPLASH_SCREEN

- (void)collectionView:(NSCollectionView *)collectionView doubleClickedOnItemAtIndex:(NSUInteger)index
{
    VLCDocumentController *controller = [VLCDocumentController sharedDocumentController];
    if (collectionView == _mediaDiscoverCollection) {
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
        id object = [[_mediaDiscoverCollection itemAtIndex:index] representedObject];
#else
        id object = [_mediaDiscovererArrayController objectAtIndex:index];
#endif
        [controller makeDocumentWithObject:object];
    }
    else {
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
        id representedObject = [[collectionView itemAtIndex:index] representedObject];
#else
        id representedObject = [[[NSUserDefaults standardUserDefaults] arrayForKey:kUnfinishedMoviesAsArray] objectAtIndex:index];
#endif
        NSString *stringURL = [representedObject valueForKey:@"url"];
        NSURL *url = [NSURL URLWithString:stringURL];
        VLCAssert(url, @"Invalid string in DB!");
        double position = [[representedObject valueForKey:@"lastPosition"] doubleValue];
        [controller makeDocumentWithURL:url andStartingPosition:position];
    }
    [[self window] close];
}

- (void)collectionView:(NSCollectionView *)collectionView willChangeSelectionIndexes:(NSIndexSet *)set
{
    if (collectionView == _mediaDiscoverCollection)
        [_unfinishedItemsCollection setSelectionIndexes:[NSIndexSet indexSet]];
    else
        [_mediaDiscoverCollection setSelectionIndexes:[NSIndexSet indexSet]];

    self.hasSelection = ([[_unfinishedItemsCollection selectionIndexes] count] > 0) || [[_mediaDiscoverCollection selectionIndexes] count] > 0 || [set count] > 0;
}

- (NSDragOperation)collectionView:(NSCollectionView *)collectionView validateDrop:(id < NSDraggingInfo >)draggingInfo proposedIndex:(NSInteger *)proposedDropIndex dropOperation:(NSCollectionViewDropOperation *)proposedDropOperation
{
    if (collectionView == _mediaDiscoverCollection)
        return NSDragOperationNone;
    return NSDragOperationGeneric;

}

- (BOOL)collectionView:(NSCollectionView *)collectionView acceptDrop:(id < NSDraggingInfo >)draggingInfo index:(NSInteger)index dropOperation:(NSCollectionViewDropOperation)dropOperation
{
    VLCAssert(collectionView == _unfinishedItemsCollection, @"Not the right collectionView");
    NSPasteboard *pboard = [draggingInfo draggingPasteboard];
    NSArray *array = [pboard propertyListForType:NSFilenamesPboardType];
    VLCAssert([array count] > 0, @"There should be at least one item dropped");

    VLCMedia *media = [VLCMedia mediaWithPath:[array objectAtIndex:0]];

    // FIXME - This is blocking and we don't have any fallback
    [media lengthWaitUntilDate:[NSDate dateWithTimeIntervalSinceNow:2]];

    [[VLCLMediaLibrary sharedMediaLibrary] media:media hasReadPosition:0];

    return YES;
}

#endif
- (IBAction)openSelection:(id)sender
{
#if !ENABLE_EXTENDED_SPLASH_SCREEN
    VLCAssert(_mediaDiscoverCollection, @"Should be binded");
    NSIndexSet *discoverers = [_mediaDiscoverCollection selectionIndexes];
    NSIndexSet *unfinished = [_unfinishedItemsCollection selectionIndexes];
    if ([discoverers count] > 0)
        [self collectionView:_mediaDiscoverCollection doubleClickedOnItemAtIndex:[discoverers firstIndex]];
    else if ([unfinished count] > 0)
         [self collectionView:_unfinishedItemsCollection doubleClickedOnItemAtIndex:[unfinished firstIndex]];
    else
         VLCAssertNotReached(@"We shouldn't have received this action in the first place");
#endif
}

#if ENABLE_EXTENDED_SPLASH_SCREEN

// See comment in definition.
- (void)loadArrayControllers
{
    [self willChangeValueForKey:@"mediaDiscovererArrayController"];

    _mediaDiscovererArrayController = [[NSArrayController alloc] init];
    [_mediaDiscovererArrayController setContent:[self availableMediaDiscoverer]];
    [_mediaDiscovererArrayController setFilterPredicate:[[self documentController] predicateThatFiltersEmptyDiscoverer]];
    [_mediaDiscovererArrayController setAutomaticallyRearrangesObjects:YES];

    [self didChangeValueForKey:@"mediaDiscovererArrayController"];
}
#endif

@end
