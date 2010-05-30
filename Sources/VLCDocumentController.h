/*****************************************************************************
 * Copyright (C) 2009 the VideoLAN team
 *
 * Authors: Felix Paul Kühne <fkuehne at videolan dot org>
 *          Pierre d'Herbemont
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
#import <VLCKit/VLCKit.h>

@class VLCSplashScreenWindowController;
@class VLCInfoWindowController;
@class VLCMovieInfoGrabberWindowController;
@class VLCTVShowInfoGrabberWindowController;
@class VLCLMediaLibrary;

@interface VLCDocumentController : NSDocumentController {
    VLCSplashScreenWindowController *_splashScreen;
    VLCMovieInfoGrabberWindowController *_movieInfoGrabber;
    VLCTVShowInfoGrabberWindowController *_tvShowInfoGrabber;
    VLCInfoWindowController *_infoWindow;

    IBOutlet NSMenuItem *_styleMenu;
    IBOutlet NSMenuItem *_scriptsMenu;

    /* various menu items containing information about our documents */
    IBOutlet NSMenuItem * _subtitleTrackSelectorMenuItem;
    IBOutlet NSMenuItem * _audioTrackSelectorMenuItem;
    IBOutlet NSMenuItem * _chapterSelectorMenuItem;
    IBOutlet NSMenuItem * _titleSelectorMenuItem;

    IBOutlet NSMenuItem *_rateMenuItem;
    IBOutlet NSView *_rateMenuView;

    id _currentDocument;

    NSArrayController *_currentArrayController;
}

/**
 * This is the front most selection for media. This
 * is what the info panel is inspecting.
 */
@property (readwrite,retain) NSArrayController *currentArrayController;

- (NSString *)typeForContentsOfURL:(NSURL *)inAbsoluteURL error:(NSError **)outError;
- (void)makeDocumentWithObject:(id)object;
- (void)makeDocumentWithURL:(NSURL *)url andStartingPosition:(double)position;
- (void)makeDocumentWithMediaDiscoverer:(VLCMediaDiscoverer *)md andMediaToPlay:(VLCMedia *)media;
- (void)makeDocumentWithMediaList:(VLCMediaList *)mediaList andName:(NSString *)name;
- (void)makeDocumentWithMediaList:(VLCMediaList *)mediaList andName:(NSString *)name andMediaToPlay:(VLCMedia *)media;

- (VLCLMediaLibrary *)mediaLibrary;

/**
 * Documents callback.
 */
- (void)documentSuggestsToRecreateMainMenu:(NSDocument *)document;
- (void)documentDidClose:(NSDocument *)document;

- (void)setMainWindow:(NSWindow *)window;

/* non Document window */
- (IBAction)openSplashScreen:(id)sender;
- (void)closeSplashScreen;

- (IBAction)openInfoWindow:(id)sender;
- (void)closeInfoWindow;

- (IBAction)openMovieInfoGrabberWindow:(id)sender;
- (IBAction)openTVShowInfoGrabberWindow:(id)sender;

/* Used by Nibs */
- (NSPredicate *)predicateThatFiltersEmptyDiscoverer;

@end
