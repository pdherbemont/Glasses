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

@interface NSResponder (StyleMenuItemHandling)
- (void)setStyleFromMenuItem:(id)sender;
@end

@implementation VLCDocumentController

- (void)awakeFromNib
{
    [NSApp setDelegate:self];
}

- (BOOL) becomeFirstResponder
{
    return YES;
}

- (NSString *)typeForContentsOfURL:(NSURL *)inAbsoluteURL error:(NSError **)outError
{
    if ([[inAbsoluteURL scheme] isEqualToString:@"http"] || [[inAbsoluteURL scheme] isEqualToString:@"mms"]
     || [[inAbsoluteURL scheme] isEqualToString:@"ftp"] || [[inAbsoluteURL scheme] isEqualToString:@"rtsp"]
     || [[inAbsoluteURL scheme] isEqualToString:@"rtmp"] || [[inAbsoluteURL scheme] isEqualToString:@"udp"]
     || [[inAbsoluteURL scheme] isEqualToString:@"file"])
    {
        return @"VLCMediaDocument";
    }

    return nil;
}

- (Class)documentClassForType:(NSString *)typeName
{
    return [VLCMediaDocument class];
}

static NSMenuItem *createStyleMenuItemWithPlugInName(NSString *name)
{
    return [[NSMenuItem alloc] initWithTitle:name action:@selector(setStyleFromMenuItem:) keyEquivalent:@""];
}

- (void)rebuildStyleMenu
{
    NSString *pluginsPath = [[NSBundle mainBundle] builtInPlugInsPath];
    NSFileManager *manager = [NSFileManager defaultManager];
    NSArray *plugins = [manager contentsOfDirectoryAtPath:pluginsPath error:nil];
    NSAssert(_styleMenu, @"There is no style menu connected");
    
    // First add the special 'Default' menu and a separator
    NSMenuItem *menuItem = createStyleMenuItemWithPlugInName(@"Default");
    [[_styleMenu submenu] addItem:menuItem];
    [menuItem release];
    [[_styleMenu submenu] addItem:[NSMenuItem separatorItem]];
    
    for (NSString *pluginPath in plugins) {
        if (![pluginPath hasSuffix:@".lunettesstyle"])
            continue;
        // Don't add the Default plugin twice
        if ([pluginPath isEqualToString:@"Default.lunettesstyle"])
            continue;
        NSString *pluginName = [[pluginPath lastPathComponent] stringByDeletingPathExtension];
        NSMenuItem *menuItem = createStyleMenuItemWithPlugInName(pluginName);
        [[_styleMenu submenu] addItem:menuItem];
        [menuItem release];
        
    }
}

static NSMenuItem *createOpenLibraryMenuItemWithDiscoverer(VLCMediaDiscoverer *mediaDiscoverer)
{
    NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[mediaDiscoverer localizedName] action:@selector(openLibraryFromMenuItem:) keyEquivalent:@""];
    [menuItem setRepresentedObject:mediaDiscoverer];
    return menuItem;
}

- (void)rebuildOpenLibraryMenu
{
    NSMenu *menu = [_openLibraryMenu submenu];
    for (NSInteger i = 0; i < [menu numberOfItems]; i++)
         [menu removeItemAtIndex:i];

    for (VLCMediaDiscoverer *mediaDiscoverer in [VLCMediaDiscoverer availableMediaDiscoverer]) {
        NSMenuItem *menuItem = createOpenLibraryMenuItemWithDiscoverer(mediaDiscoverer);
        [menu addItem:menuItem];
        [menuItem release];
    }
}

- (void)openLibraryFromMenuItem:(id)sender
{
    VLCMediaDocument *mediaDocument = [[VLCMediaDocument alloc] initWithMediaList:[[sender representedObject] discoveredMedia]];
    [self addDocument:mediaDocument];
    [mediaDocument makeWindowControllers];
    [mediaDocument showWindows];
    [mediaDocument release];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    [self rebuildStyleMenu];
    [self rebuildOpenLibraryMenu];

    // We have some document open already, don't bother to show the splashScreen.
    if ([[self documents] count] > 0)
        return;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    static NSString *dontShowSplashScreenKey = @"DontShowSplashScreen";
    if ([defaults boolForKey:dontShowSplashScreenKey])
        return;

    // auto-releases itself when the window is closed
    _splashScreen = [[VLCSplashScreenWindowController alloc] init];
    [[_splashScreen window] makeKeyAndOrderFront:self];
    [_splashScreen setShouldCloseDocument:NO];

    // The _splashScreen will autorelease itself when done, forget about the reference now.
    _splashScreen = nil;
}

@end
