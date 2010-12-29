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
#if !ENABLE_EXTENDED_SPLASH_SCREEN
    IBOutlet NSArrayController *_mediaDiscovererArrayController;
#else
    NSArrayController *_mediaDiscovererArrayController;
#endif

    IBOutlet NSArrayController *_clipsArrayController;
    IBOutlet NSArrayController *_moviesArrayController;
    IBOutlet NSArrayController *_tvShowsArrayController;
    IBOutlet NSArrayController *_tvShowEpisodesArrayController;
    IBOutlet NSArrayController *_labelsArrayController;

    NSArray *availableMediaDiscoverer;

#if !ENABLE_EXTENDED_SPLASH_SCREEN
    IBOutlet NSCollectionView *_unfinishedItemsCollection;
    IBOutlet NSCollectionView *_mediaDiscoverCollection;
    BOOL _hasSelection;
#endif
}

@property (retain, readonly) NSArrayController *mediaDiscovererArrayController;
@property (retain, readonly) NSArrayController *clipsArrayController;
@property (retain, readonly) NSArrayController *moviesArrayController;
@property (retain, readonly) NSArrayController *tvShowsArrayController;
@property (retain, readonly) NSArrayController *tvShowEpisodesArrayController;
@property (retain, readonly) NSArrayController *labelsArrayController;

#if ENABLE_EXTENDED_SPLASH_SCREEN
/* This methods is used to load the loadable arrayControllers.
 * This is used by VLCSplashScreenView to ensure that we will
 * load them after loading the view. For instance the mediaDiscovererArrayController
 * is time consuming to create, and postponing its creation results in visible
 * speed gain when opening the splashscreen. */
- (void)loadArrayControllers;
#endif

// Content of mediaDiscovererArrayController
@property (retain, readonly) NSArray *availableMediaDiscoverer;

#if !ENABLE_EXTENDED_SPLASH_SCREEN
/* Used in xib, for the "Open" button enabled state */
@property (assign, readonly) BOOL hasSelection;
#endif

- (IBAction)openSelection:(id)sender;
@end
