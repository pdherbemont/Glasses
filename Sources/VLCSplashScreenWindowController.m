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

- (void)collectionView:(NSCollectionView *)collectionView doubleClickedOnItemAtIndex:(NSUInteger)idx
{
    VLCDocumentController *controller = [VLCDocumentController sharedDocumentController];
    if (collectionView == _mediaDiscoverCollection)
        [controller makeDocumentWithObject:[[self availableMediaDiscoverer] objectAtIndex:idx]];
    else {
        id representedObject = [[[NSUserDefaults standardUserDefaults] arrayForKey:kUnfinishedMoviesAsArray] objectAtIndex:idx];
        NSURL *url = [NSURL URLWithString:[[representedObject objectForKey:@"url"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        double position = [[representedObject objectForKey:@"position"] doubleValue];
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
    id object = [[self availableMediaDiscoverer] objectAtIndex:[[_mediaDiscoverCollection selectionIndexes] firstIndex]];
#endif
    [[VLCDocumentController sharedDocumentController] makeDocumentWithObject:object];
    [[self window] resignMainWindow];
}
@end
