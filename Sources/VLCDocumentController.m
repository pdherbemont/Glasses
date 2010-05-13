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

#import "VLCDocumentController.h"
#import "VLCMediaDocument.h"
#import "VLCSplashScreenWindowController.h"
#import "VLCInfoWindowController.h"
#import "VLCMediaLibrary.h"
#import "VLCMovieInfoGrabberWindowController.h"
#import "VLCTVShowInfoGrabberWindowController.h"

#import <VLCKit/VLCExtensionsManager.h>
#import <VLCKit/VLCExtension.h>

#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_5
#import "VLCCompatibilityAdditions.h"
#endif

@interface NSResponder (FirstResponder)
- (void)setStyleFromMenuItem:(id)sender;
- (void)setSubtitleTrackFromMenuItem:(NSMenuItem *)sender;
- (void)setSubtitleTrackFromFileWithMenuItem:(NSMenuItem *)sender;
- (void)setAudioTrackFromMenuItem:(NSMenuItem *)sender;
- (void)setChapterFromMenuItem:(NSMenuItem *)sender;
- (void)setTitleFromMenuItem:(NSMenuItem *)sender;
@end

@interface VLCDocumentController ()

// See -setMainWindow:
@property (readwrite, assign) id currentDocument;

@end

@implementation VLCDocumentController
@synthesize currentDocument=_currentDocument;
@synthesize currentArrayController=_currentArrayController;

- (void)dealloc
{
    [_tvShowInfoGrabber release];
    [_movieInfoGrabber release];
    [_splashScreen release];
    [_currentArrayController release];
    [super dealloc];
}

- (void)awakeFromNib
{
    [NSApp setDelegate:self];
}

- (BOOL)becomeFirstResponder
{
    return YES;
}

- (NSString *)typeForContentsOfURL:(NSURL *)inAbsoluteURL error:(NSError **)outError
{
    NSString *scheme = [[inAbsoluteURL scheme] lowercaseString];
    NSArray *schemes = [NSArray arrayWithObjects:
                        @"file", @"ftp", @"http", @"mms", @"qtcapture", @"rtmp",
                        @"rtp", @"rtsp", @"udp", nil];

    CFIndex index = CFArrayBSearchValues((CFArrayRef) schemes, CFRangeMake(0, CFArrayGetCount((CFArrayRef)schemes)) , 
                                     (CFStringRef) scheme, (CFComparatorFunction)CFStringCompare, nil);
    if ((index < [schemes count]) && [[schemes objectAtIndex:index] isEqualToString:scheme]) {
        return @"VLCMediaDocument";
    }
    NSRunCriticalAlertPanel(@"Lunettes does not support this protocol",
                            [NSString stringWithFormat:@"%@ is no valid URL scheme.", scheme],
                            @"OK", nil, nil);
    return nil;
}

- (Class)documentClassForType:(NSString *)typeName
{
    return [VLCMediaDocument class];
}

#pragma mark -
#pragma mark Main Menu Cleanup and Recreation

static NSMenuItem *createStyleMenuItemWithPlugInName(NSString *name)
{
    return [[NSMenuItem alloc] initWithTitle:name action:@selector(setStyleFromMenuItem:) keyEquivalent:@""];
}

- (void)rebuildStyleMenu
{
    NSString *pluginsPath = [[NSBundle mainBundle] builtInPlugInsPath];
    NSFileManager *manager = [NSFileManager defaultManager];
    NSArray *plugins = [manager contentsOfDirectoryAtPath:pluginsPath error:nil];
    VLCAssert(_styleMenu, @"There is no style menu connected");

    // First add the special 'Default' menu and a separator
    NSMenu *submenu = [_styleMenu submenu];
    NSMenuItem *menuItem = createStyleMenuItemWithPlugInName(@"Default");
    [submenu addItem:menuItem];
    [menuItem release];
    [submenu addItem:[NSMenuItem separatorItem]];

    for (NSString *pluginPath in plugins) {
        if (![pluginPath hasSuffix:@".lunettesstyle"])
            continue;
        // Don't add the Default plugin twice
        if ([pluginPath isEqualToString:@"Default.lunettesstyle"])
            continue;
        NSString *pluginName = [[pluginPath lastPathComponent] stringByDeletingPathExtension];
        NSMenuItem *menuItem = createStyleMenuItemWithPlugInName(pluginName);
        [submenu addItem:menuItem];
        [menuItem release];

    }
}

- (void)runScriptFromMenuItem:(id)sender
{
    VLCAssert([sender isKindOfClass:[NSMenuItem class]], @"should be a menuItem");
    NSMenuItem *item = (NSMenuItem *)sender;
    [[VLCExtensionsManager sharedManager] runExtension:[item representedObject]];
}

- (void)showAboutScriptsWindow:(id)sender
{
    NSRunAlertPanel(@"About VLC Scripts", @"Nothing interesting for now", @"OK", nil, nil);
}

static NSMenuItem *createScriptsMenuItemWithExtension(VLCExtension *extension)
{
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[extension title] action:@selector(runScriptFromMenuItem:) keyEquivalent:@""];
    [item setRepresentedObject:extension];
    return item;
}

- (void)rebuildScriptsMenu
{
    VLCAssert(_scriptsMenu, @"There is no style menu connected");

    NSMenu *submenu = [_scriptsMenu submenu];

    VLCExtensionsManager *manager = [VLCExtensionsManager sharedManager];
    for (VLCExtension *extension in [manager extensions]) {
        NSMenuItem *menuItem = createScriptsMenuItemWithExtension(extension);
        [submenu addItem:menuItem];
        [menuItem release];
    }
    [submenu addItem:[NSMenuItem separatorItem]];
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:@"About VLC Scripts..." action:@selector(showAboutScriptsWindow:) keyEquivalent:@""];
    [submenu addItem:item];
    [item release];

    [manager bind:@"mediaPlayer" toObject:self withKeyPath:@"currentDocument.mediaListPlayer.mediaPlayer" options:nil];
}

- (void)rebuildRateMenuItem
{
    VLCAssert(_rateMenuItem, @"_rateMenuItem should be connected");
    VLCAssert(_rateMenuView, @"_rateMenuView should be connected");
    [_rateMenuItem setView:_rateMenuView];
}

static void addTrackMenuItems(NSMenuItem *parentMenuItem, SEL sel, NSArray *items, NSUInteger currentItemIndex)
{
    NSMenu *parentMenu = [parentMenuItem submenu];
    NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Disable" action:sel keyEquivalent:@""];
    [menuItem setTag:0];
    [menuItem setAlternate:YES];
    [parentMenu addItem:menuItem];
    [menuItem release];

    [parentMenu addItem:[NSMenuItem separatorItem]];

    // Start at 1 since the first item of the NSArray is the disabled state.
    for (NSUInteger x = 1; x < [items count]; x++) {
        menuItem = [[NSMenuItem alloc] initWithTitle:[items objectAtIndex:x] action:sel keyEquivalent:@""];
        [menuItem setTag:x];
        [parentMenu addItem:menuItem];
        [menuItem release];
    }
    if ([parentMenu numberOfItems] > 2) {
        [[parentMenu itemWithTag:currentItemIndex] setState:NSOnState];
        [parentMenuItem setEnabled:YES];
    }
}


- (void)cleanAndRecreateMainMenu
{
    VLCMediaDocument *currentDocument = [self currentDocument];

    [_subtitleTrackSelectorMenuItem setEnabled:NO];
    [_audioTrackSelectorMenuItem setEnabled:NO];
    [_titleSelectorMenuItem setEnabled:NO];
    [_chapterSelectorMenuItem setEnabled:NO];

    VLCMediaPlayer *thePlayer = [[currentDocument mediaListPlayer] mediaPlayer];

    if ([thePlayer state] == VLCMediaPlayerStatePlaying || [thePlayer state] == VLCMediaPlayerStatePaused) {
        // Subtitle menu
        // this is a special case to allow opening of external subtitle file
        NSMenu *menu = [_subtitleTrackSelectorMenuItem submenu];
        [menu removeAllItems];
        NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Open Subtitle File..." action:@selector(setSubtitleTrackFromFileWithMenuItem:) keyEquivalent:@""];
        [menu addItem:menuItem];
        [menuItem release];
        [_subtitleTrackSelectorMenuItem setEnabled:YES];
        [menu addItem:[NSMenuItem separatorItem]];
        addTrackMenuItems(_subtitleTrackSelectorMenuItem, @selector(setSubtitleTrackFromMenuItem:), [thePlayer videoSubTitles], [thePlayer currentVideoSubTitleIndex]);

        if ([menu numberOfItems] == 4) {
            [menu removeItemAtIndex:3]; // separator
            [menu removeItemAtIndex:2]; // "Disable"
            [menu removeItemAtIndex:1]; // separator
        }

        // Audiotrack menu
        [[_audioTrackSelectorMenuItem submenu] removeAllItems];
        addTrackMenuItems(_audioTrackSelectorMenuItem, @selector(setAudioTrackFromMenuItem:), [thePlayer audioTracks], [thePlayer currentAudioTrackIndex]);

        NSArray *titles = [thePlayer titles];

        // Title selector menu
        [[_titleSelectorMenuItem submenu] removeAllItems];
        addTrackMenuItems(_titleSelectorMenuItem, @selector(setTitleFromMenuItem:), titles, [thePlayer currentTitleIndex]);

        // Chapter Selector menu
        [[_chapterSelectorMenuItem submenu] removeAllItems];

        NSArray *chapters = [titles count] > 0 ? [thePlayer chaptersForTitleIndex:[thePlayer currentTitleIndex]] : [NSArray array];
        NSUInteger currentChapterIndex = [titles count] > 0 ? [thePlayer currentChapterIndex] : NSNotFound;
        addTrackMenuItems(_chapterSelectorMenuItem, @selector(setChapterFromMenuItem:), chapters, currentChapterIndex);
    }
}

- (void)bakeDocument:(VLCMediaDocument *)mediaDocument
{
    [self addDocument:mediaDocument];
    [mediaDocument makeWindowControllers];
    [mediaDocument showWindows];
}

- (void)makeDocumentWithMediaList:(VLCMediaList *)mediaList andName:(NSString *)name andMediaToPlay:(VLCMedia *)media
{
    VLCMediaDocument *mediaDocument = [[VLCMediaDocument alloc] initWithMediaList:mediaList andName:name];
    [self bakeDocument:mediaDocument];
    if (media)
        [[mediaDocument mediaListPlayer] playMedia:media];
    [mediaDocument release];
}

- (void)makeDocumentWithMediaList:(VLCMediaList *)mediaList andName:(NSString *)name
{
    [self makeDocumentWithMediaList:mediaList andName:name andMediaToPlay:nil];
}

- (void)makeDocumentWithURL:(NSURL *)url andStartingPosition:(double)position
{
    VLCMediaDocument *mediaDocument = [[VLCMediaDocument alloc] initWithContentsOfURL:url andStartingPosition:position];
    [self bakeDocument:mediaDocument];
    [mediaDocument release];
}

- (void)makeDocumentWithMediaDiscoverer:(VLCMediaDiscoverer *)md andMediaToPlay:(VLCMedia *)media
{
    VLCMediaDocument *mediaDocument = [[VLCMediaDocument alloc] initWithMediaList:[md discoveredMedia] andName:[md localizedName]];
    [self bakeDocument:mediaDocument];
    [[mediaDocument mediaListPlayer] playMedia:media];
    [mediaDocument release];
}

- (void)makeDocumentWithObject:(id)object
{
    if ([object isKindOfClass:[VLCMediaList class]])
        [self makeDocumentWithMediaList:object andName:nil];
    else if ([object isKindOfClass:[VLCMediaDiscoverer class]])
        [self makeDocumentWithMediaList:[object discoveredMedia] andName:[object localizedName]];
    else
        VLCAssertNotReached(@"No idea how to open that object");
}

- (void)openLibraryFromMenuItem:(id)sender
{
    [self makeDocumentWithObject:[sender representedObject]];
}

- (NSPredicate *)predicateThatFiltersEmptyDiscoverer
{
    return [NSPredicate predicateWithFormat:@"discoveredMedia.media.@count != 0"];
}


#pragma mark -
#pragma mark Documents Callbacks
- (void)documentSuggestsToRecreateMainMenu:(NSDocument *)document
{
    [self cleanAndRecreateMainMenu];
}

- (void)documentDidClose:(NSDocument *)document
{
    if ([[self documents] count] != 0)
        return;

    // Reopen the splash screen when last visible window is closed.
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:kDontShowSplashScreen])
        return;
    [self openSplashScreen:self];
}

#pragma mark -
#pragma mark Non document-based window
- (IBAction)openSplashScreen:(id)sender
{
    BOOL didCreateWindow = NO;
    if (!_splashScreen) {
        _splashScreen = [[VLCSplashScreenWindowController alloc] init];
        didCreateWindow = YES;
    }
    [_splashScreen showWindow:self];

    // Scan folder it after showing the window.
    // The window creating might trigger a local runloop
    // and we don't want this to run in the run loop.

    if (didCreateWindow)
        [[VLCLMediaLibrary sharedMediaLibrary] performSelector:@selector(setupFolderWatch) withObject:nil afterDelay:0.];
}

- (void)closeSplashScreen
{
    [_splashScreen close];
    [_splashScreen release];
    _splashScreen = nil;
}

- (IBAction)openInfoWindow:(id)sender
{
    if (!_infoWindow) {
        // auto-releases itself when the window is closed
        _infoWindow = [[VLCInfoWindowController alloc] init];
    }
    [_infoWindow showWindow:self];
}

- (void)closeInfoWindow
{
    [_infoWindow release];
    _infoWindow = nil;
}

- (IBAction)openMovieInfoGrabberWindow:(id)sender
{
    if (!_movieInfoGrabber) {
        _movieInfoGrabber = [[VLCMovieInfoGrabberWindowController alloc] init];
    }
    [_movieInfoGrabber showWindow:self];
}

- (IBAction)openTVShowInfoGrabberWindow:(id)sender
{
    if (!_tvShowInfoGrabber) {
        _tvShowInfoGrabber = [[VLCTVShowInfoGrabberWindowController alloc] init];
    }
    [_tvShowInfoGrabber showWindow:self];
}


- (void)setMainWindow:(NSWindow *)window
{
    // Cocoa doesn't properly update the currentDocument
    // because we use borderless window.
    // We need to work around this.
    [self setCurrentDocument:[self documentForWindow:window]];

    // Recreate the main menu from here.
    [self cleanAndRecreateMainMenu];
}

- (VLCLMediaLibrary *)mediaLibrary
{
    return [VLCLMediaLibrary sharedMediaLibrary];
}

#pragma mark -
#pragma mark NSApp delegate

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    [[VLCLMediaLibrary sharedMediaLibrary] savePendingChanges];

    if (![[NSUserDefaults standardUserDefaults] synchronize])
        VLCAssertNotReached(@"Failed to synchronize the User Defaults");

    return NSTerminateNow;
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)application hasVisibleWindows:(BOOL)visibleWindows
{
    if (!visibleWindows) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if ([defaults boolForKey:kDontShowSplashScreen])
            return YES;
        [self openSplashScreen:self];
        return NO;
    }
    return YES;
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
    // Load VLC from now on.
    [VLCLibrary sharedLibrary];

    // We have some document open already, don't bother to show the splashScreen.
    if ([[self documents] count] > 0)
        return;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:kDontShowSplashScreen])
        return;

    [self openSplashScreen:nil];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    [self rebuildStyleMenu];
    [self rebuildScriptsMenu];
    [self rebuildRateMenuItem];
}
@end
