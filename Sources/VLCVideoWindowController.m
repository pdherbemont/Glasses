//
//  VLCVideoWindowController.m
//  Glasses
//
//  Created by Pierre d'Herbemont on 8/22/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

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
#pragma mark fullscreenHUDWindowControllerDelegate

- (BOOL)fullscreen
{
    return [_videoView fullscreen];
}

- (void)setFullscreen:(BOOL)fullscreen
{
	[_videoView setFullscreen:fullscreen];
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
            // we've got an error here, unknown button set to display
            NSAlert *alert = [NSAlert alertWithMessageText:@"An unknown error occured during playback" defaultButton:@"Oh Oh" alternateButton:nil otherButton:nil
                             informativeTextWithFormat:@"An unknown error occured when playing %@", [[mediaPlayer media] url]];
            [alert runModal];            
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
	if([mediaPlayer isPlaying]) {
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
	[self setFullscreen:![self fullscreen]];
}

@end
