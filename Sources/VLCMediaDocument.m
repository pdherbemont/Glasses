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
#import "VLCPlaylistDebugWindowController.h"
#import "VLCExportStatusWindowController.h"

@interface VLCMediaDocument ()
@property (readwrite,retain) VLCMediaListPlayer * mediaListPlayer;
@end

@implementation VLCMediaDocument
@synthesize mediaListPlayer=_mediaListPlayer;

- (id)initWithContentsOfURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
    self = [super initWithContentsOfURL:absoluteURL ofType:typeName error:outError];
	if(!self)
        return nil;
    _media = [[VLCMedia mediaWithURL:absoluteURL] retain];

	return self;
}

- (id)initWithMediaList:(VLCMediaList *)mediaList andName:(NSString *)name
{
    self = [super init];
	if(!self)
        return nil;
    _mediaList = [mediaList retain];
    _name = [name copy];
	return self;
}

- (void)dealloc
{
    [_name release];
	[_media release];
	[_mediaList release];

    NSAssert(!_mediaListPlayer, @"The current media player should be removed in -close");

	[super dealloc];
}

- (void)close
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_mediaListPlayer stop];
    [_mediaListPlayer.mediaPlayer setDelegate:nil];
    self.mediaListPlayer = nil;
    [super close];
}

- (NSString *)displayName
{
    if (_name)
        return _name;
    return [super displayName];
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

    VLCMediaListPlayer *mediaListPlayer = [[VLCMediaListPlayer alloc] init];
    [mediaListPlayer.mediaPlayer setVideoView:videoView];
    self.mediaListPlayer = mediaListPlayer;
	[videoView setMediaPlayer:mediaListPlayer.mediaPlayer];
    [mediaListPlayer.mediaPlayer setDelegate:self];
    if (_media)
        [mediaListPlayer setRootMedia:_media];
    else
        [mediaListPlayer setMediaList:_mediaList];
    [mediaListPlayer play];

    [mediaListPlayer release];

    [windowController release];
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
    if (outError)
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
    return YES;
}


- (void)saveToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation delegate:(id)delegate didSaveSelector:(SEL)didSaveSelector contextInfo:(void *)contextInfo
{
    NSLog(@"%@", absoluteURL);
    VLCStreamSession *streamSession = [VLCStreamSession streamSession];
    streamSession.media = _media;
    streamSession.streamOutput = [VLCStreamOutput ipodStreamOutputWithFilePath:[[[absoluteURL absoluteString] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"file://localhost" withString:@""]];
    
    VLCExportStatusWindowController *exportWindowController = [[VLCExportStatusWindowController alloc] init];
    [[exportWindowController window] makeKeyAndOrderFront:self];
    exportWindowController.streamSession = streamSession;
    
    [streamSession startStreaming];
}

- (NSArray *)writableTypesForSaveOperation:(NSSaveOperationType)saveOperation
{
    return [NSArray arrayWithObject:(NSString*)kUTTypeMPEG4];
}

#pragma mark -
#pragma mark VLCMediaPlayer delegate

- (void)mediaPlayerStateChanged:(NSNotification *)aNotification
{
    VLCMediaPlayer *mediaPlayer = _mediaListPlayer.mediaPlayer;
    VLCMediaPlayerState state = [mediaPlayer state];
    switch (state) {
        case VLCMediaPlayerStateError:
        {
            // we've got an error here, unknown button set to display
            NSAlert *alert = [NSAlert alertWithMessageText:@"An unknown error occured during playback" defaultButton:@"Oh Oh" alternateButton:nil otherButton:nil
                                 informativeTextWithFormat:@"An unknown error occured when playing %@", [[mediaPlayer media] url]];
            [alert runModal];
            //[self close];
            break;            
        }
        case VLCMediaPlayerStatePlaying:
        default:
            break;
    }
}

#pragma mark -
#pragma mark First responder

- (void)showDebugPlaylist:(id)sender
{
    VLCPlaylistDebugWindowController *windowController = [[VLCPlaylistDebugWindowController alloc] init];
    [self addWindowController:windowController];
    [[windowController window] makeKeyAndOrderFront:self];
    [windowController release];
}


- (void)remoteMiddleButtonPressed:(id)sender
{
    if (![_mediaListPlayer.mediaPlayer isPlaying]) {
        [_mediaListPlayer play];
    }
    else {
        [_mediaListPlayer.mediaPlayer pause];
    }

}

- (void)remoteMenuButtonPressed:(id)sender
{
    [NSApp sendAction:@selector(toggleFullscreen:) to:nil];
}

- (void)remoteUpButtonPressed:(id)sender
{
    [_mediaListPlayer.mediaPlayer.audio volumeUp];
}

- (void)remoteDownButtonPressed:(id)sender
{
    [_mediaListPlayer.mediaPlayer.audio volumeDown];
}

- (void)remoteRightButtonPressed:(id)sender
{
    VLCMediaPlayer *mediaPlayer = _mediaListPlayer.mediaPlayer;
    if (![mediaPlayer isSeekable]) {
        NSBeep();
        return;
    }
    
    [mediaPlayer mediumJumpForward];
}

- (void)remoteLeftButtonPressed:(id)sender
{
    VLCMediaPlayer *mediaPlayer = _mediaListPlayer.mediaPlayer;
    if (![mediaPlayer isSeekable]) {
        NSBeep();
        return;
    }
    
    [mediaPlayer mediumJumpBackward];
}

@end
