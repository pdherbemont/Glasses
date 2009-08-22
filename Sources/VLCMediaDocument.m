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

#import "VLCMediaDocument.h"

@interface VLCMediaDocument () <VLCFullscreenHUDWindowControllerDelegate>
@property (readwrite,retain) VLCMediaPlayer * mediaPlayer;
@end

@implementation VLCMediaDocument
@synthesize mediaPlayer=_mediaPlayer;

- (id)initWithContentsOfURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
	if((self = [super initWithContentsOfURL:absoluteURL ofType:typeName error:outError]))
	{
		_media = [[VLCMedia mediaWithURL:absoluteURL] retain];
	}
	return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[_fullscreenHUDWindowController release];
	[_media release];
	[_mediaPlayer stop];
	self.mediaPlayer = nil;

	[super dealloc];
}

- (NSString *)windowNibName
{
    return @"MediaDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];

	NSRect frame;
	NSWindow * window = [aController window];
	frame = [[window screen] frame];
	frame.size.width = frame.size.width / 3;
	frame.size.height = frame.size.height / 3;
	
	[window setFrame:frame display:NO];
	[window center];

	self.mediaPlayer = [[[VLCMediaPlayer alloc] initWithVideoView:_videoView] autorelease];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaPlayerStateChanged:) name:VLCMediaPlayerStateChanged object:nil];
    [self.mediaPlayer setDelegate:self];
	[_videoView setMediaPlayer:_mediaPlayer];
	[_mediaPlayer setMedia:_media];
	[_mediaPlayer play];
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    if (outError)
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    if (outError)
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
    return YES;
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
    if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
    return YES;
}

#pragma mark -
#pragma mark VLCMediaPlayer delegate
- (void)mediaPlayerStateChanged:(NSNotification *)aNotification
{
    /* FIXME: VLCKit doesn't call this method correctly (neither as delegate or through notifications) */
    if ([self.mediaPlayer state] == VLCMediaPlayerStateStopped || [self.mediaPlayer state] == VLCMediaPlayerStateEnded) {
        /* stream is stopped, let's show the play icon */
        NSLog( @"stream ended or was stopped (%@)", [self.mediaPlayer state] );
        [_playPauseButton setImage:[NSImage imageNamed:@"play_embedded"]];
        [_playPauseButton setAlternateImage:[NSImage imageNamed:@"play_embedded_graphite"]];
    } else if([self.mediaPlayer state] == VLCMediaPlayerStateError) {
        /* we've got an error here, unknown button set to display */
        NSAlert * alert;
        alert = [NSAlert alertWithMessageText:@"An unknown error occured during playback" defaultButton:@"Oh Oh" alternateButton:nil otherButton:nil informativeTextWithFormat:@"An unknown error occured when playing %@", [[self.mediaPlayer media] url]];
        [alert runModal];
    }
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
#pragma mark IBAction

- (IBAction)togglePlayPause:(id)sender
{
	if([_mediaPlayer isPlaying]) {
		[_mediaPlayer pause];
        [sender setImage:[NSImage imageNamed:@"play_embedded"]];
        [sender setAlternateImage:[NSImage imageNamed:@"play_embedded_graphite"]];
    } else {
		[_mediaPlayer play];
        [sender setImage:[NSImage imageNamed:@"pause_embedded"]];
        [sender setAlternateImage:[NSImage imageNamed:@"pause_embedded_graphite"]];
    }
}

- (IBAction)toggleFullscreen:(id)sender
{
	[self setFullscreen:![self fullscreen]];
}
@end
