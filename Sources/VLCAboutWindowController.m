/*****************************************************************************
* Copyright (C) 2009 the VideoLAN team
* $Id: $
*
* Authors: Felix Paul Kühne <fkuehne at videolan dot org>
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

#import "VLCAboutWindowController.h"


@implementation VLCGPLWindowController

static VLCGPLWindowController *_sharedGPLInstance = nil;

- (NSString *)windowNibName
{
    return @"AboutWindow";
}

- (IBAction)showWindow:(id)sender
{
    [_gpl_field setString: [NSString stringWithUTF8String: psz_license]];
    [[self window] center];
    [[self window] makeKeyAndOrderFront: self];
}

@end

@implementation VLCAboutWindowController

- (NSString *)windowNibName
{
    return @"AboutWindow";
}

- (void)awakeFromNib
{
    [[self window] setDelegate: self];
    _gplWindowController = [[VLCGPLWindowController alloc] init];

    /* Get the localized info dictionary (InfoPlist.strings) */
    NSDictionary *_localDict;
    _localDict = [[NSBundle mainBundle] infoDictionary];

    /* Setup the copyright field */
    [_copyright_field setStringValue:[NSString stringWithFormat:@"%@", [_localDict objectForKey:@"NSHumanReadableCopyright"]]];

    /* Setup the nameversion field */
    [_version_field setStringValue:[NSString stringWithFormat:@"Version %@", [_localDict objectForKey:@"CFBundleVersion"]]];

    /* setup the authors and thanks field */
    [_credits_textview setString: [NSString stringWithFormat: @"%@\n%@\n\n%@", 
                                   [NSString stringWithUTF8String:psz_genericAbout], 
                                   [NSString stringWithUTF8String:psz_authors], 
                                   [NSString stringWithUTF8String:psz_thanks]]];

    /* Setup the window */
    [_credits_textview setDrawsBackground: NO];
    [_credits_scrollview setDrawsBackground: NO];
    [[self window] setExcludedFromWindowsMenu:YES];
    [[self window] setMenu:nil];
    [[self window] center];
}

- (void)dealloc
{
    [_gplWindowController release];
    [_scrollTimer invalidate];

    [super dealloc];
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{
    _scrollTimer = [NSTimer scheduledTimerWithTimeInterval: 1/6
                                                      target:self
                                                    selector:@selector(scrollCredits:)
                                                    userInfo:nil
                                                     repeats:YES];
}

- (void)windowDidResignKey:(NSNotification *)notification
{
    [_scrollTimer invalidate];
}

- (IBAction)showWindow:(id)sender
{
    /* Show the window */
    b_restart = YES;
    [_credits_textview scrollPoint:NSMakePoint(0,0)];
    [[self window] makeKeyAndOrderFront: sender];
}

- (IBAction)showGPL:(id)sender
{
    [_gplWindowController showWindow: sender];
}

- (void)scrollCredits:(NSTimer *)timer
{
    if( b_restart )
    {
        /* Reset the starttime */
        i_start = [NSDate timeIntervalSinceReferenceDate] + 6.0;
        f_current = 0;
        f_end = [_credits_textview bounds].size.height - [_credits_scrollview bounds].size.height;
        b_restart = NO;
    }
    
    if( [NSDate timeIntervalSinceReferenceDate] >= i_start )
    {
        /* Scroll to the position */
        [_credits_textview scrollPoint:NSMakePoint( 0, f_current )];
        
        /* Increment the scroll position */
        f_current += 0.005;
        
        /* If at end, restart at the top */
        if( f_current >= f_end )
        {
            [_credits_textview scrollPoint:NSMakePoint(0,0)];
            b_restart = YES;
        }
    }
}

@end


