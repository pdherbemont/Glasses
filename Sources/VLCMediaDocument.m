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
#import "VLCDocumentController.h"

@interface VLCMediaDocument ()
@property (readwrite,retain) VLCMediaListPlayer * mediaListPlayer;
- (void)startToRememberMediaPosition;
- (void)stopRememberMediaPosition;
@end

@implementation VLCMediaDocument
@synthesize mediaListPlayer=_mediaListPlayer;
@synthesize sharedOnLAN=_sharedOnLAN;

- (id)initWithContentsOfURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
    self = [super initWithContentsOfURL:absoluteURL ofType:typeName error:outError];
	if(!self)
        return nil;
    _media = [[VLCMedia mediaWithURL:absoluteURL] retain];
	return self;
}

- (id)initWithContentsOfURL:(NSURL *)absoluteURL andStartingPosition:(double)position
{
    self = [self initWithContentsOfURL:absoluteURL ofType:(NSString *)kUTTypeMovie error:nil];
	if(!self)
        return nil;
    _startingPosition = position;
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
    NSAssert(!_rememberTimer, @"This timer should be closed");

    [_name release];
	[_media release];
	[_mediaList release];

    NSAssert(!_mediaListPlayer, @"The current media player should be removed in -close");

	[super dealloc];
}

- (IBAction)saveVideoSnapshot:(id)sender
{
    NSString *path = [[NSUserDefaults standardUserDefaults] stringForKey:@"SelectedSnapshotFolder"];
    [[self mediaListPlayer].mediaPlayer saveVideoSnapshotAt:[path stringByExpandingTildeInPath] withWidth:0 andHeight:0];
}

/**
 * This is also by VLCApplication, at app exit.
 * FIXME: This probably need a reiteration.
 */
- (void)saveUnfinishedMovieState
{
    VLCMediaPlayer *mediaPlayer = _mediaListPlayer.mediaPlayer;

    BOOL seekable = [mediaPlayer isSeekable];
    double position = [mediaPlayer position];
    VLCTime *remainingTime = [mediaPlayer remainingTime];
    VLCMedia *media = _media ? _media : mediaPlayer.media;

    if (media && seekable) {
        VLCDocumentController *documentController = [VLCDocumentController sharedDocumentController];
        [documentController media:media wasClosedAtPosition:position withRemainingTime:remainingTime];
        if (_sharedOnLAN)
            [_theLANStreamingSession setPosition: position];
    }
}

- (void)close
{
    // Cocoa might call -close multiple time for each Window Controller, do -close only once.
    if (_isClosed)
        return;
    _isClosed = YES;

    [self stopRememberMediaPosition];
    [self saveUnfinishedMovieState];

    if (_sharedOnLAN)
    {
        [_theLANStreamingSession stopStreaming];
        [_theLANStreamingSession release];
    }

    [_mediaListPlayer stop];
    [_mediaListPlayer.mediaPlayer setDelegate:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self];

    // Make sure we remove the MediaListPlayer at the very last
    // Because our window needs to be closed first.
    // That's what [super close] does.
    [super close];

    self.mediaListPlayer = nil;
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
    VLCStreamSession * theStreamSession;
    VLCMedia * ourMedia = _media;
    if (!ourMedia)
    {
        NSRunCriticalAlertPanel(@"Export failed", @"Lunettes cannot export media from list-based players yet. Please open the input separately to convert it.", @"Hum, okay", nil, nil);
        return;
    }
    theStreamSession = [VLCStreamSession streamSession];
    theStreamSession.media = ourMedia;
    if ([typeName isEqualToString:(NSString*)kUTTypeMPEG])
        theStreamSession.streamOutput = [VLCStreamOutput mpeg2StreamOutputWithFilePath:[[[absoluteURL absoluteString] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"file://localhost" withString:@""]];
    else if ([typeName isEqualToString:(NSString*)kUTTypeMPEG4])
    {
        theStreamSession.streamOutput = [VLCStreamOutput mpeg2StreamOutputWithFilePath:[[[absoluteURL absoluteString] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"file://localhost" withString:@""]];
    }
    else
    {
        VLCAssertNotReached(@"unsupported file type requested");
    }

    VLCExportStatusWindowController *exportWindowController = [[VLCExportStatusWindowController alloc] init];
    [[exportWindowController window] makeKeyAndOrderFront:self];
    exportWindowController.streamSession = theStreamSession;

    [exportWindowController.streamSession startStreaming];
    [self addWindowController:exportWindowController];
    [exportWindowController release];
}

- (IBAction)shareMovieOnLAN:(NSMenuItem *)sender
{
    if (!_sharedOnLAN) {
        VLCMedia *ourMedia = _media;
        if (!ourMedia)
        {
            NSRunCriticalAlertPanel(@"Sharing failed", @"Lunettes cannot share media from list-based players yet. Please open the input separately.", @"Hum, okay", nil, nil);
            return;
        }
        _theLANStreamingSession = [VLCStreamSession streamSession];
        _theLANStreamingSession.media = ourMedia;
        _theLANStreamingSession.streamOutput = [VLCStreamOutput rtpBroadcastStreamOutputWithSAPAnnounce: [self displayName]];
        _sharedOnLAN = YES;
        [_theLANStreamingSession startStreaming];
        if ([_mediaListPlayer.mediaPlayer isSeekable])
            [_theLANStreamingSession setPosition: _mediaListPlayer.mediaPlayer.position];
        [_theLANStreamingSession retain];
    } else {
        [_theLANStreamingSession stopStreaming];
        [_theLANStreamingSession release];
        _sharedOnLAN = NO;
    }
}

- (void)playbackPositionChanged
{
    // This method is triggered by the VLCStyledVideoWindowView, when the position slider is moved by the user
    if (_sharedOnLAN)
    {
        VLCMediaPlayer *mediaPlayer = _mediaListPlayer.mediaPlayer;

        if ([mediaPlayer isSeekable])
            [_theLANStreamingSession setPosition: [mediaPlayer position]];
    }
}

- (NSArray *)writableTypesForSaveOperation:(NSSaveOperationType)saveOperation
{
    return [NSArray arrayWithObjects:(NSString*)kUTTypeMPEG, (NSString*)kUTTypeMPEG4, nil];
}

- (void)didFinishLoadingWindowController:(NSWindowController *)controller
{
    // Initiate playback only when the window controller tells us that it
    // is fully loaded. Our window controller do async loading because
    // they load webview.
    // This is to make sure that we play only once the webview is loaded.
    // This way we wont overload the CPU during opening.
    
    if (_hasInitiatedPlayback)
        return;
    _hasInitiatedPlayback = YES;
    VLCMediaList *mediaListPlayer = [self mediaListPlayer];
    [mediaListPlayer play];
    [mediaListPlayer.mediaPlayer setPosition:_startingPosition];
}

#pragma mark -
#pragma mark Remember current playing state

// To support sudden termination to save the last playing position
// we setup a timer during playback that will fire and save the current playing
// position.
// The other cool benefit is that we resist to crash. This makes an other
// IO every now and then. But this is low, and we hope the system will cache it.
- (void)startToRememberMediaPosition
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DontRememberMediaPosition"])
        return;
    static const NSTimeInterval mediaPositionPollingInterval = 10.0;
    _rememberTimer = [[NSTimer timerWithTimeInterval:mediaPositionPollingInterval target:self selector:@selector(saveUnfinishedMovieState) userInfo:nil repeats:YES] retain];
    [[NSRunLoop mainRunLoop] addTimer:_rememberTimer forMode:NSDefaultRunLoopMode];
}

- (void)stopRememberMediaPosition
{
    [_rememberTimer invalidate];
    [_rememberTimer release];
    _rememberTimer = nil;
}


#pragma mark -
#pragma mark VLCMediaPlayer delegate

- (void)mediaPlayerStateChanged:(NSNotification *)aNotification
{
    VLCMediaPlayer *mediaPlayer = _mediaListPlayer.mediaPlayer;
    VLCMediaPlayerState state = [mediaPlayer state];
    if (state == VLCMediaPlayerStateError) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"An unknown error occured during playback" defaultButton:@"Oh Oh" alternateButton:nil otherButton:nil
                             informativeTextWithFormat:@"An unknown error occured when playing %@", [[mediaPlayer media] url]];
        [alert runModal];
        
    }

    if (state == VLCMediaPlayerStatePlaying)
        [self startToRememberMediaPosition];
    else {
        [self stopRememberMediaPosition];
        [self saveUnfinishedMovieState];
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
