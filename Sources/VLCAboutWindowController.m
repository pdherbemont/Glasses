//
//  VLCAboutWindowController.m
//  Lunettes
//
//  Created by Felix Paul Kühne on 28.08.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "VLCAboutWindowController.h"


@implementation VLCGPLWindowController

static VLCGPLWindowController *_sharedGPLInstance = nil;

+ (VLCGPLWindowController *)sharedInstance
{
    return _sharedGPLInstance ? _sharedGPLInstance : [[self alloc] init];
}

- (id)init
{
    if (_sharedGPLInstance) {
        [self dealloc];
    } else {
        _sharedGPLInstance = [super init];
    }
    
    return _sharedGPLInstance;
}

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

static VLCAboutWindowController *_sharedAboutInstance = nil;

+ (VLCAboutWindowController *)sharedInstance
{
    return _sharedAboutInstance ? _sharedAboutInstance : [[self alloc] init];
}

- (id)init
{
    if (_sharedAboutInstance) {
        [self dealloc];
    } else {
        _sharedAboutInstance = [super init];
    }
    
    return _sharedAboutInstance;
}

- (NSString *)windowNibName
{
    return @"AboutWindow";
}

- (void)awakeFromNib
{
    [[self window] setDelegate: self];
    _gpl_win_controller = [[VLCGPLWindowController alloc] init];

    /* Get the localized info dictionary (InfoPlist.strings) */
    NSDictionary *_local_dict;
    _local_dict = [[NSBundle mainBundle] infoDictionary];

    /* Setup the copyright field */
    [_copyright_field setStringValue:[NSString stringWithFormat:@"%@", [_local_dict objectForKey:@"NSHumanReadableCopyright"]]];

    /* Setup the nameversion field */
    [_name_version_field setStringValue:[NSString stringWithFormat:@"Version %@", [_local_dict objectForKey:@"CFBundleVersion"]]];

    /* setup the authors and thanks field */
    [_credits_textview setString: [NSString stringWithFormat: @"%@\n%@\n\n%@", 
                                   [NSString stringWithUTF8String:psz_generic_about], 
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
    [_gpl_win_controller release];
    [_scroll_timer invalidate];

    [super dealloc];
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{
    _scroll_timer = [NSTimer scheduledTimerWithTimeInterval: 1/6
                                                      target:self
                                                    selector:@selector(scrollCredits:)
                                                    userInfo:nil
                                                     repeats:YES];
}

- (void)windowDidResignKey:(NSNotification *)notification
{
    [_scroll_timer invalidate];
}

- (IBAction)showWindow:(id)sender
{
    /* Show the window */
    b_restart = YES;
    [_credits_textview scrollPoint:NSMakePoint(0,0)];
    [[self window] makeKeyAndOrderFront: nil];
}

- (IBAction)showGPL:(id)sender
{
    [_gpl_win_controller showWindow: sender];
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


