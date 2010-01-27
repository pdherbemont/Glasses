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

@interface VLCDocumentController : NSDocumentController {
    VLCSplashScreenWindowController *_splashScreen;
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

    NSManagedObjectContext *_managedObjectContext;
    NSManagedObjectModel   *_managedObjectModel;
}

- (NSString *)typeForContentsOfURL:(NSURL *)inAbsoluteURL error:(NSError **)outError;
- (void)makeDocumentWithObject:(id)object;
- (void)makeDocumentWithURL:(NSURL *)url andStartingPosition:(double)position;

- (void)media:(VLCMedia *)media wasClosedAtPosition:(double)position;

- (IBAction)openSplashScreen:(id)sender;
- (void)closeSplashScreen;

- (void)cleanAndRecreateMainMenu;

- (void)setMainWindow:(NSWindow *)window;

- (NSManagedObjectContext *)managedObjectContext;
@end
