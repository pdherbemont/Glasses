/*****************************************************************************
 * VLCApplication.m: NSApplication subclass
 *****************************************************************************
 * Copyright (C) 2009-2010 the VideoLAN team
 * $Id:$
 *
 * Authors:Felix Paul Kühne <fkuehne at videolan dot org>
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

#import <WebKit/WebKit.h>

#import <IOKit/hidsystem/ev_keymap.h>         /* for the media key support */

#import "VLCApplication.h"
#import "VLCStyledVideoWindowController.h"
#import "VLCMediaDocument.h"
#import "VLCDocumentController.h"
#import "VLCExceptionHandler.h"

@interface NSObject (RemoteResponder)
- (void)remoteMiddleButtonPressed:(id)sender;
- (void)remoteMenuButtonPressed:(id)sender;
- (void)remoteUpButtonPressed:(id)sender;
- (void)remoteDownButtonPressed:(id)sender;
- (void)remoteRightButtonPressed:(id)sender;
- (void)remoteLeftButtonPressed:(id)sender;
@end

@interface VLCApplication ()
@property BOOL controlWithMediaKeysInBackground;
@property BOOL controlWithRemote;
@property BOOL controlWithMediaKeys;
@end

@implementation VLCApplication

- (void)awakeFromNib
{
    [[VLCExceptionHandler sharedHandler] setup];

    // FIXME: -awakeFromNib is certainly not the right place to do the following
    WebPreferences *preferences = [WebPreferences standardPreferences];
    [preferences setCacheModel:WebCacheModelDocumentViewer];
    [preferences setUsesPageCache:NO];

    /* register our default values... */
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *yes = [NSNumber numberWithBool:YES];
    NSNumber *no = [NSNumber numberWithBool:NO];
    [defaults registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
                                yes, kControlWithMediaKeys,
                                yes, kControlWithMediaKeysInBackground,
                                yes, kControlWithHIDRemote,
                                yes, kUseDeinterlaceFilter,
                                yes, kShowDebugMenu,
                                @"~/Desktop", kSelectedSnapshotFolder,
                                [NSArray arrayWithObjects:
                                 [@"~/Movies" stringByExpandingTildeInPath],
                                 [@"~/Downloads" stringByExpandingTildeInPath], nil], kScannedFolders,
                                no, kLastFMEnabled, nil]];

    // Setup the URL cache.
    NSURLCache *cache = [NSURLCache sharedURLCache];
    [cache setDiskCapacity:500 * (1ULL << 20) /* 500MB */];
    [cache setMemoryCapacity:5 * (1ULL << 20)   /* 5MB */];
    NSLog(@"\nCache\n\tdisk size: %dkB / %dkB\n\tmemory size: %dkB / %dkB",
          [cache currentDiskUsage] / 1 << 10,
          [cache diskCapacity] / 1 << 10,
          [cache currentMemoryUsage]/ 1 << 10,
          [cache memoryCapacity]/ 1 << 10);

    // Always reset if the WebKitInspector was attached.
    // Because its mostly unusable else.
    [defaults setBool:NO forKey:@"WebKitInspectorAttached"];
    // This one for latest WebKit versions.
    [defaults setBool:NO forKey:@"WebKit Web Inspector Setting - inspectorStartsAttached"];

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(applicationDidBecomeActiveOrInactive:) name:@"NSApplicationDidBecomeActiveNotification" object:nil];
    [center addObserver:self selector:@selector(applicationDidBecomeActiveOrInactive:) name:@"NSApplicationWillResignActiveNotification" object:nil];
    [center addObserver:self selector:@selector(applicationDidFinishLaunching:) name:@"NSApplicationDidFinishLaunchingNotification" object:nil];

    /* init Apple Remote support */
    _remote = [[AppleRemote alloc] init];
    [_remote setClickCountEnabledButtons:kRemoteButtonPlay];
    [_remote setListeningOnAppActivate:YES];
    [_remote setDelegate:self];

    NSUserDefaultsController *controller = [NSUserDefaultsController sharedUserDefaultsController];
    [self bind:@"controlWithRemote" toObject:controller withKeyPath:@"values.ControlWithHIDRemote" options:nil];
    [self bind:@"controlWithMediaKeys" toObject:controller withKeyPath:@"values.ControlWithMediaKeys" options:nil];
    [self bind:@"controlWithMediaKeysInBackground" toObject:controller withKeyPath:@"values.ControlWithMediaKeysInBackground" options:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_crashReporter release];
    [_remote stopListening:self];
    [_remote release];
    [super dealloc];
}

//- (void)reportException:(NSException *)anException
//{
//	// Make sure our VLCExceptionHandler get this exception
//	[[VLCExceptionHandler sharedHandler] handleUncaughtException:anException];
//}
//
- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    /* handle existing crash reports and send if needed */
    _crashReporter = [[VLCCrashReporter alloc] init];
    if ([_crashReporter latestCrashLogPathPreviouslySeen:NO]) {
        NSLog(@"Found log: %@",[_crashReporter latestCrashLogPathPreviouslySeen:YES]);
        [_crashReporter showUserDialog];
    }
    else
        [_crashReporter release];
}

#pragma mark -
#pragma mark Apple Remote Control

/* Helper method for the remote control interface in order to trigger forward/backward and volume
 increase/decrease as long as the user holds the left/right, plus/minus button */
- (void)executeHoldActionForRemoteButton:(NSNumber *)buttonIdentifierNumber
{
    if (_remoteButtonIsHold) {
        switch ([buttonIdentifierNumber intValue]) {
            case kRemoteButtonRight_Hold:
                [NSApp sendAction:@selector(remoteRightButtonPressed:) to:nil from:self];
                break;
            case kRemoteButtonLeft_Hold:
                [NSApp sendAction:@selector(remoteLeftButtonPressed:) to:nil from:self];
                break;
            case kRemoteButtonVolume_Plus_Hold:
                [NSApp sendAction:@selector(remoteUpButtonPressed:) to:nil from:self];
                break;
            case kRemoteButtonVolume_Minus_Hold:
                [NSApp sendAction:@selector(remoteDownButtonPressed:) to:nil from:self];
                break;
        }
        if (_remoteButtonIsHold) {
            /* trigger event */
            [self performSelector:@selector(executeHoldActionForRemoteButton:)
                       withObject:buttonIdentifierNumber
                       afterDelay:0.25];
        }
    }
}

/* Apple Remote callback */
- (void)appleRemoteButton:(AppleRemoteEventIdentifier)buttonIdentifier pressedDown:(BOOL)pressedDown clickCount:(unsigned int)count
{
    BOOL ret = NO;
    switch (buttonIdentifier) {
        case kRemoteButtonPlay:
            ret = [NSApp sendAction:@selector(remoteMiddleButtonPressed:) to:nil from:self];
            break;
        case kRemoteButtonMenu:
            ret = [NSApp sendAction:@selector(remoteMenuButtonPressed:) to:nil from:self];
            break;
        case kRemoteButtonVolume_Plus:
            ret = [NSApp sendAction:@selector(remoteUpButtonPressed:) to:nil from:self];
            break;
        case kRemoteButtonVolume_Minus:
            ret = [NSApp sendAction:@selector(remoteDownButtonPressed:) to:nil from:self];
            break;
        case kRemoteButtonRight:
            ret = [NSApp sendAction:@selector(remoteRightButtonPressed:) to:nil from:self];
            break;
        case kRemoteButtonLeft:
            ret = [NSApp sendAction:@selector(remoteLeftButtonPressed:) to:nil from:self];
            break;
        case kRemoteButtonRight_Hold:
        case kRemoteButtonLeft_Hold:
        case kRemoteButtonVolume_Plus_Hold:
        case kRemoteButtonVolume_Minus_Hold:
            /* simulate an event as long as the user holds the button */
            _remoteButtonIsHold = pressedDown;
            if (pressedDown) {
                NSNumber *buttonIdentifierNumber = [NSNumber numberWithInt:buttonIdentifier];
                [self performSelector:@selector(executeHoldActionForRemoteButton:)
                           withObject:buttonIdentifierNumber];
            }
            ret = YES; // FIXME?
            break;
        default:
            /* Add here whatever you want other buttons to do */
            break;
    }
    if (!ret)
        NSBeep();
}

- (void)applicationDidBecomeActiveOrInactive:(NSNotification *)notification
{
    BOOL hasResignedActive = [[notification name] isEqualToString:@"NSApplicationWillResignActiveNotification"];
    if ((hasResignedActive && !_isActiveInBackground ) || !_hasMediaKeySupport)
        _isActive = NO;
    else
        _isActive = YES;
}

#pragma mark -
#pragma mark Preferences Bindings

@synthesize controlWithMediaKeysInBackground=_isActiveInBackground;

- (BOOL)controlWithRemote
{
    return _controlWithRemote;
}

- (void)setControlWithRemote:(BOOL)support
{
    _controlWithRemote = support;
    if (support)
        [_remote startListening:self];
    else
        [_remote stopListening:self];
}


#pragma mark -
#pragma mark media key support on Al Apple keyboards

- (BOOL)controlWithMediaKeys
{
    return _hasMediaKeySupport;
}

- (void)setControlWithMediaKeys:(BOOL)support
{
    _isActive = _hasMediaKeySupport = support;
}

- (void)sendEvent:(NSEvent *)event
{
    if (_isActive) {
        if ([event type] == NSSystemDefined && [event subtype] == 8) {
            NSInteger keyCode =  ([event data1] & 0xFFFF0000) >> 16;
            NSInteger keyFlags = [event data1] & 0x0000FFFF;
            NSInteger keyState = ((keyFlags & 0xFF00) >> 8) == 0xA;
            NSInteger keyRepeat = keyFlags & 0x1;

            VLCMediaPlayer *mediaPlayer = [[[[NSDocumentController sharedDocumentController] currentDocument] mediaListPlayer] mediaPlayer];

            if (keyCode == NX_KEYTYPE_PLAY && keyState == 0 && [mediaPlayer canPause])
                [mediaPlayer pause];

            /* _hasJustJumped is required as the keyboard sends its events faster than the user can actually jump through his/her media */
            if (keyCode == NX_KEYTYPE_FAST && !_hasJustJumped) {
                if (keyRepeat == 1) {
                    [mediaPlayer shortJumpForward];
                    _hasJustJumped = YES;
                    [self performSelector:@selector(resetJump) withObject:nil afterDelay:0.25];
                }
            }

            if (keyCode == NX_KEYTYPE_REWIND && !_hasJustJumped) {
                if (keyRepeat == 1) {
                    [mediaPlayer shortJumpBackward];
                    _hasJustJumped = YES;
                    [self performSelector:@selector(resetJump) withObject:nil afterDelay:0.25];
                }
            }
        }
    }
    [super sendEvent:event];
}

- (void)resetJump
{
    _hasJustJumped = NO;
}


#pragma mark -
#pragma mark IB Action

- (IBAction)reportBug:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://trac.videolan.org"]];
}

- (IBAction)showVideoLANWebsite:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.videolan.org"]];
}

- (IBAction)runCommandLineVLC:(id)sender
{
    static const char const *scriptFormat =
    "tell application \"Terminal\"\n"
    "activate\n"
    "do script \"export PATH=%@:$PATH\nvlc -H | less\"\n"
    "end tell\n";

    NSBundle *bundle = [NSBundle bundleWithIdentifier:@"org.videolan.vlckitframework"];

    NSString *vlc = [NSString stringWithFormat:@"%@/bin", [bundle bundlePath]];
    vlc = [vlc stringByReplacingOccurrencesOfString:@" " withString:@"\\ "];
    vlc = [vlc stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];

    NSAppleScript *script = [[NSAppleScript alloc] initWithSource:
                             [NSString stringWithFormat:[NSString stringWithUTF8String:scriptFormat], vlc]];

    [script executeAndReturnError:nil];
    [script release];
}

@end

