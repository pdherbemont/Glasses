/*****************************************************************************
 * Copyright (C) 2009 the VideoLAN team
 *
 * Authors: Pierre d'Herbemont
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

#import <VLCKit/VLCKit.h>

#import "VLCVideoWindowController.h"
#import "VLCMediaDocument.h"


@implementation VLCVideoWindowController
@synthesize videoView=_videoView;
- (VLCMediaDocument *)mediaDocument
{
    return (VLCMediaDocument *)[self document];
}

- (VLCMediaPlayer *)mediaPlayer
{
    return [self mediaDocument].mediaListPlayer.mediaPlayer;
}

- (void)close
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super close];
}

- (NSString *)windowNibName
{
    return @"VideoWindow";
}

- (void)windowDidLoad
{
    [super windowDidLoad];
	NSWindow * window = [self window];

	NSRect frame = [[window screen] frame];
	frame.size.width = frame.size.width / 3;
	frame.size.height = frame.size.height / 3;

	[window setFrame:frame display:NO];
	[window center];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaPlayerStateChanged:) name:VLCMediaPlayerStateChanged object:[self mediaDocument].mediaListPlayer.mediaPlayer];
}


#pragma mark -
#pragma mark VLCMediaPlayer delegate

- (void)mediaPlayerStateChanged:(NSNotification *)aNotification
{
    // FIXME: VLCKit doesn't call this method correctly (neither as delegate or through notifications)
    VLCMediaPlayer *mediaPlayer = [self mediaPlayer];
    VLCMediaPlayerState state = [mediaPlayer state];
    switch (state) {
        case VLCMediaPlayerStateStopped:
        case VLCMediaPlayerStateEnded:
        {
            // stream is stopped, let's show the play icon
            VLCLogDebug(@"stream ended or was stopped (%i)", state);
            [_playPauseButton setImage:[NSImage imageNamed:@"play_embedded"]];
            [_playPauseButton setAlternateImage:[NSImage imageNamed:@"play_embedded_graphite"]];
            break;
        }
        case VLCMediaPlayerStateError:
        {
            break;
        }
        default:
            break;
    }
}

#pragma mark -
#pragma mark IBAction

- (IBAction)togglePlayPause:(id)sender
{
    VLCMediaPlayer *mediaPlayer = [self mediaPlayer];
	if ([mediaPlayer isPlaying]) {
		[mediaPlayer pause];
        [sender setImage:[NSImage imageNamed:@"play_embedded"]];
        [sender setAlternateImage:[NSImage imageNamed:@"play_embedded_graphite"]];
    } else {
		[mediaPlayer play];
        [sender setImage:[NSImage imageNamed:@"pause_embedded"]];
        [sender setAlternateImage:[NSImage imageNamed:@"pause_embedded_graphite"]];
    }
}

- (IBAction)toggleFullscreen:(id)sender
{
}

@end
