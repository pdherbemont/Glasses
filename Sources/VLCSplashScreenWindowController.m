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

#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
@interface VLCSplashScreenWindowController () <NSWindowDelegate>
@end
#endif

@implementation VLCSplashScreenWindowController

- (NSArray *)availableMediaDiscoverer
{
    return [VLCMediaDiscoverer availableMediaDiscoverer];
}

- (NSString *)windowNibName
{
    return @"SplashScreenWindow";
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    NSWindow *window = [self window];

    [window center];
    [window setDelegate:self];
    NSAssert(_mediaDiscoverCollection, @"There is no collectionView");
}

- (void)windowWillClose:(NSNotification *)notification
{
    [[VLCDocumentController sharedDocumentController] closeSplashScreen];
}

/**
 * This methods is being used by the bindings of the services view.
 */
- (VLCDocumentController *)documentController
{
    return [VLCDocumentController sharedDocumentController];
}

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
        NSURL *url = [NSURL URLWithString:[representedObject valueForKey:@"url"]];
        double position = [[representedObject valueForKey:@"lastPosition"] doubleValue];
        [controller makeDocumentWithURL:url andStartingPosition:position];
    }
}

- (IBAction)openSelectedMediaDiscoverer:(id)sender
{
    NSAssert(_mediaDiscoverCollection, @"Should be binded");
    NSInteger index = [[_mediaDiscoverCollection selectionIndexes] firstIndex];
    NSAssert(index != NSNotFound, @"We shouldn't have received this action in the first place");
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    id object = [[_mediaDiscoverCollection itemAtIndex:index] representedObject];
#else
    id object = [_mediaDiscovererArrayController objectAtIndex:index];
#endif
    [[VLCDocumentController sharedDocumentController] makeDocumentWithObject:object];
    [[self window] resignMainWindow];
}
@end
