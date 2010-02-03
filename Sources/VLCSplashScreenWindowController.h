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

#import <Cocoa/Cocoa.h>

#import "VLCFeatures.h"

@interface VLCSplashScreenWindowController : NSWindowController
{
    IBOutlet NSArrayController *_mediaDiscovererArrayController;
    BOOL _hasSelection;

#if !ENABLE_EXTENDED_SPLASH_SCREEN
    IBOutlet NSCollectionView *_unfinishedItemsCollection;
    IBOutlet NSCollectionView *_mediaDiscoverCollection;
#endif
}

@property (retain, readonly) NSArray *availableMediaDiscoverer;

/* Used in xib, for the "Open" button enabled state */
@property (assign, readonly) BOOL hasSelection;

- (IBAction)openSelection:(id)sender;
@end
