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
#import "VLCStyledVideoWindowController.h"
#import "VLCVideoWindowController.h"
#import "VLCFeatures.h"

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
	[_fullscreenHUDWindowController release];
	[_media release];
	[_mediaPlayer stop];
	self.mediaPlayer = nil;

	[super dealloc];
}

- (void)close
{
    self.mediaPlayer = nil;
    [super close];
}

- (void)makeWindowControllers
{
#if USE_STYLED_WINDOW
    VLCStyledVideoWindowController *windowController = [[VLCStyledVideoWindowController alloc] init];
#else
    VLCVideoWindowController *windowController = [[VLCVideoWindowController alloc] init];
#endif
    [self addWindowController:windowController];

    // Force the window controller to load its window
    [windowController window];

    VLCExtendedVideoView *videoView = windowController.videoView;
    NSAssert(videoView, @"There should be a videoView at this point");

    VLCMediaPlayer *mediaPlayer = [[VLCMediaPlayer alloc] initWithVideoView:videoView];
    self.mediaPlayer = mediaPlayer;
	[videoView setMediaPlayer:mediaPlayer];
	[mediaPlayer setMedia:_media];
    [mediaPlayer play];
    [mediaPlayer release];

    [windowController release];
}

- (void)windowControllerDidLoadNib:(NSWindowController *)windowController
{
    NSAssert(!self.mediaPlayer, @"There shouldn't be a media player still around");
    
    
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

@end
