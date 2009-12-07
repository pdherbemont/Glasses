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

@interface VLCSplashScreenWindowController () <NSWindowDelegate>
@end

@implementation VLCSplashScreenWindowController

- (NSString *)windowNibName
{
    return @"SplashScreenWindow";
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    [[self window] center];
    [[self window] setDelegate: self];
}

- (void)windowWillClose:(NSNotification *)notification
{
    [self autorelease];
}

/**
 * This methods is being used by the bindings of the services view.
 */
- (VLCDocumentController *)documentController
{
    return [VLCDocumentController sharedDocumentController];
}

- (void)collectionView:(NSCollectionView *)collectionView doubleClickedOnItem:(NSCollectionViewItem *)item
{
    VLCDocumentController *controller = [VLCDocumentController sharedDocumentController];
    if (collectionView == _mediaDiscoverCollection)
        [controller makeDocumentWithObject:[item representedObject]];
    else {
        NSURL *url = [NSURL URLWithString:[[item representedObject] objectForKey:@"url"]];
        [controller openDocumentWithContentsOfURL:url display:YES error:nil];
    }
}

- (IBAction)openSelectedMediaDiscoverer:(id)sender
{
    NSAssert(_mediaDiscoverCollection, @"Should be binded");
    NSInteger index = [[_mediaDiscoverCollection selectionIndexes] firstIndex];
    NSAssert(index != NSNotFound, @"We shouldn't have received this action in the first place");
    id object = [[_mediaDiscoverCollection itemAtIndex:index] representedObject];
    [[VLCDocumentController sharedDocumentController] makeDocumentWithObject:object];
    [[self window] resignMainWindow];
}
@end
