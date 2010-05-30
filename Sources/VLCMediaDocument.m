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
#import "VLCMediaLibrary.h"

@interface VLCMediaDocument ()
@property (readwrite,retain) VLCMediaListPlayer *mediaListPlayer;
@property (readwrite,retain) NSArrayController *currentArrayController;

- (void)startToRememberMediaPosition;
- (void)stopRememberMediaPosition;
@end

@implementation VLCMediaDocument
@synthesize mediaListPlayer=_mediaListPlayer;
@synthesize currentArrayController=_currentArrayController;

- (id)initWithContentsOfURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
    self = [super initWithContentsOfURL:absoluteURL ofType:typeName error:outError];
	if (!self)
        return nil;
    _media = [[VLCMedia mediaWithURL:absoluteURL] retain];
	return self;
}

- (id)initWithContentsOfURL:(NSURL *)absoluteURL andStartingPosition:(double)position
{
    self = [self initWithContentsOfURL:absoluteURL ofType:(NSString *)kUTTypeMovie error:nil];
	if (!self)
        return nil;
    _startingPosition = position;
	return self;
}

- (id)initWithMediaList:(VLCMediaList *)mediaList andName:(NSString *)name
{
    self = [super init];
	if (!self)
        return nil;
    _mediaList = [mediaList retain];
    _name = [name copy];
	return self;
}

- (void)dealloc
{
    VLCAssert(!_rememberTimer, @"This timer should be closed");

    [_name release];
	[_media release];
	[_mediaList release];

    VLCAssert(!_mediaListPlayer, @"The current media player should be removed in -close");

	[super dealloc];
}

- (IBAction)saveVideoSnapshot:(id)sender
{
    NSString *path = [[NSUserDefaults standardUserDefaults] stringForKey:kSelectedSnapshotFolder];
    [[self mediaListPlayer].mediaPlayer saveVideoSnapshotAt:[path stringByExpandingTildeInPath] withWidth:0 andHeight:0];
}

/**
 * This methods calls back the VLCDocumentController,
 * asking it to save the state of this movie.
 * By state we mean the position, in order to be able
 * to reset back to where we were at next opening.
 *
 * This is called at periodic intervals.
 *
 * FIXME: This probably need a reiteration.
 */
- (void)saveUnfinishedMovieState
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDontRememberUnfinishedMovies])
        return;

    VLCMediaPlayer *mediaPlayer = _mediaListPlayer.mediaPlayer;
    VLCAssert(mediaPlayer, @"There is no media Player, the following is incorrect");

    BOOL seekable = [mediaPlayer isSeekable];
    double position = [mediaPlayer position];
    VLCMedia *media = _media ? _media : mediaPlayer.media;

    if (media && seekable) {
        [[VLCLMediaLibrary sharedMediaLibrary] media:media hasReadPosition:position];
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

    if (_isSharedOnLAN) {
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

    [[VLCDocumentController sharedDocumentController] documentDidClose:self];
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
    VLCAssert(videoView, @"There should be a videoView at this point");

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
    if (!ourMedia) {
        NSRunCriticalAlertPanel(@"Export failed", @"Lunettes cannot export media from list-based players yet. Please open the input separately to convert it.", @"Hum, okay", nil, nil);
        return;
    }
    theStreamSession = [VLCStreamSession streamSession];
    theStreamSession.media = ourMedia;
    if ([typeName isEqualToString:(NSString *)kUTTypeMPEG])
        theStreamSession.streamOutput = [VLCStreamOutput mpeg2StreamOutputWithFilePath:[[[absoluteURL absoluteString] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"file://localhost" withString:@""]];
    else if ([typeName isEqualToString:(NSString *)kUTTypeMPEG4]) {
        theStreamSession.streamOutput = [VLCStreamOutput mpeg2StreamOutputWithFilePath:[[[absoluteURL absoluteString] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"file://localhost" withString:@""]];
    }
    else {
        VLCAssertNotReached(@"unsupported file type requested");
    }

    VLCExportStatusWindowController *exportWindowController = [[VLCExportStatusWindowController alloc] init];
    [[exportWindowController window] makeKeyAndOrderFront:self];
    exportWindowController.streamSession = theStreamSession;

    [exportWindowController.streamSession startStreaming];
    [self addWindowController:exportWindowController];
    [exportWindowController release];
}

- (NSArray *)writableTypesForSaveOperation:(NSSaveOperationType)saveOperation
{
    return [NSArray arrayWithObjects:(NSString *)kUTTypeMPEG, (NSString *)kUTTypeMPEG4, nil];
}

- (BOOL)isDocumentEdited
{
    return NO;
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
    VLCMediaListPlayer *mediaListPlayer = [self mediaListPlayer];
    [mediaListPlayer play];
    [mediaListPlayer.mediaPlayer setPosition:_startingPosition];
    if (_isSharedOnLAN)
        [_theLANStreamingSession setPosition:_startingPosition];
}

#pragma mark -
#pragma mark Accessors

- (VLCMediaPlayer *)mediaPlayer
{
    return [self mediaListPlayer].mediaPlayer;
}

+ (NSSet *)keyPathsForValuesAffectingRootMediaList
{
    return [NSSet setWithObjects:@"mediaListPlayer.rootMedia.subitems.count", @"mediaListPlayer.mediaList", nil];
}

- (VLCMediaList *)rootMediaList
{
    VLCMediaListPlayer *player = [self mediaListPlayer];
    VLCMediaList *mainMediaContent = player.rootMedia.subitems;
    BOOL isPlaylistDocument = mainMediaContent.count > 0;
    return isPlaylistDocument ? mainMediaContent : player.mediaList;
}

#pragma mark -
#pragma mark Sharing

- (void)setIsSharedOnLAN:(BOOL)share
{
    if (_isSharedOnLAN == share)
        return;

    if (share) {
        VLCMedia *ourMedia = _media;
        if (!ourMedia) {
            // FIXME - We need to support this.
            NSRunCriticalAlertPanel(@"Sharing failed", @"Lunettes cannot share media from list-based players yet. Please open the input separately.", @"Hum, okay", nil, nil);
            return;
        }
        VLCAssert(!_theLANStreamingSession, @"There should not be a _theLANStreamingSession at this time.");
        _theLANStreamingSession = [[VLCStreamSession streamSession] retain];
        _theLANStreamingSession.media = ourMedia;
        _theLANStreamingSession.streamOutput = [VLCStreamOutput rtpBroadcastStreamOutputWithSAPAnnounce:[self displayName]];
        _isSharedOnLAN = YES;
        [_theLANStreamingSession startStreaming];
        if ([_mediaListPlayer.mediaPlayer isSeekable])
            [_theLANStreamingSession setPosition:_mediaListPlayer.mediaPlayer.position];
    } else {
        [_theLANStreamingSession stopStreaming];
        [_theLANStreamingSession release];
        _theLANStreamingSession = nil;
        _isSharedOnLAN = NO;
    }
}

- (BOOL)isSharedOnLAN
{
    return _isSharedOnLAN;
}

- (void)playbackPositionChanged
{
    // This method is triggered by the VLCStyledVideoWindowView, when the position slider is moved by the user
    if (!_isSharedOnLAN)
        return;

    VLCMediaPlayer *mediaPlayer = _mediaListPlayer.mediaPlayer;

    if ([mediaPlayer isSeekable])
        [_theLANStreamingSession setPosition:[mediaPlayer position]];
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
    // There is already one timer running, don't start it twice.
    if (_rememberTimer)
        return;

    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDontRememberUnfinishedMovies])
        return;
    static const NSTimeInterval mediaPositionPollingInterval = 10.0;
    VLCAssert(!_rememberTimer, @"There shouldn't be a timer at this point");
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
#pragma mark Playback mode
- (void)setRepeatCurrentItem:(BOOL)repeat
{
    // This depends on repeatAllItems.
    // When we set this to true, we need to invalidate
    // repeatAllItems.
    // And we want to set the no repeat flag only if both
    // of the two options are not selected.

    _repeatCurrentItem = repeat;
    if (repeat) {
        [_mediaListPlayer setRepeatMode:VLCRepeatCurrentItem];
        [self setRepeatAllItems:NO];
    }

    if (!_repeatAllItems && !_repeatCurrentItem)
        [_mediaListPlayer setRepeatMode:VLCDoNotRepeat];
}

- (BOOL)repeatCurrentItem
{
    return _repeatCurrentItem;
}

- (void)setRepeatAllItems:(BOOL)repeat
{
    // See comment in -setRepeatCurrentItem:.

    _repeatAllItems = repeat;
    if (repeat) {
        [_mediaListPlayer setRepeatMode:VLCRepeatAllItems];
        [self setRepeatCurrentItem:NO];
    }

    if (!_repeatAllItems && !_repeatCurrentItem)
        [_mediaListPlayer setRepeatMode:VLCDoNotRepeat];
}

- (BOOL)repeatAllItems
{
    return _repeatAllItems;
}

#pragma mark -
#pragma mark VLCMediaPlayer delegate

- (void)mediaPlayerStateChanged:(NSNotification *)aNotification
{
    VLCMediaPlayer *mediaPlayer = _mediaListPlayer.mediaPlayer;
    VLCMediaPlayerState state = [mediaPlayer state];

    if (state == VLCMediaPlayerStatePlaying) {
        [self startToRememberMediaPosition];
        [[VLCDocumentController sharedDocumentController] documentSuggestsToRecreateMainMenu:self];
    } else {
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

#pragma mark -
#pragma mark Action
- (IBAction)stepForward:(id)sender
{
    VLCMediaPlayer *mediaPlayer = _mediaListPlayer.mediaPlayer;
    if (![mediaPlayer isSeekable]) {
        NSBeep();
        return;
    }

    [mediaPlayer shortJumpForward];
}

- (IBAction)stepBackward:(id)sender
{
    VLCMediaPlayer *mediaPlayer = _mediaListPlayer.mediaPlayer;
    if (![mediaPlayer isSeekable]) {
        NSBeep();
        return;
    }

    [mediaPlayer shortJumpBackward];
}

- (IBAction)gotoNextFrame:(id)sender
{
    [_mediaListPlayer.mediaPlayer gotoNextFrame];
}

#pragma mark Remote Control
- (void)remoteMiddleButtonPressed:(id)sender
{
    if (![_mediaListPlayer.mediaPlayer isPlaying])
        [_mediaListPlayer play];
    else
        [_mediaListPlayer.mediaPlayer pause];
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
    [self stepForward:sender];
}

- (void)remoteLeftButtonPressed:(id)sender
{
    [self stepBackward:sender];
}

#pragma mark Playback Menu Items
- (void)setSubtitleTrackFromMenuItem:(NSMenuItem *)sender
{
    [[[self mediaListPlayer] mediaPlayer] setCurrentVideoSubTitleIndex:[sender tag]];
    [[VLCDocumentController sharedDocumentController] documentSuggestsToRecreateMainMenu:self];
}

- (void)setSubtitleTrackFromFileWithMenuItem:(NSMenuItem *)sender
{
    NSOpenPanel * openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseFiles:YES];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setAllowsMultipleSelection:YES];
    [openPanel beginSheetForDirectory:nil
                                 file:nil
                                types:[NSArray arrayWithObjects:@"cdg", @"@idx", @"srt", @"sub", @"utf", @"ass", @"ssa", @"aqt", @"jss", @"psb", @"rt", @"smi", nil]
                       modalForWindow:[self windowForSheet]
                        modalDelegate:self
                       didEndSelector:@selector(openSubtitleFileFromPanel:returnCode:contextInfo:)
                          contextInfo:nil];
}

- (void)openSubtitleFileFromPanel:(NSOpenPanel *)panel
                       returnCode:(NSInteger)returnCode
                      contextInfo:(void  *)contextInfo
{
    if (returnCode == NSOKButton) {
        for (NSUInteger i = 0; i < [[panel filenames] count] ; i++)
            [[[self mediaListPlayer] mediaPlayer] openVideoSubTitlesFromFile:[[panel filenames] objectAtIndex:i]];
        [[VLCDocumentController sharedDocumentController] documentSuggestsToRecreateMainMenu:self];
    }
}

- (void)setAudioTrackFromMenuItem:(NSMenuItem *)sender
{
    [[[self mediaListPlayer] mediaPlayer] setCurrentAudioTrackIndex:[sender tag]];
    [[VLCDocumentController sharedDocumentController] documentSuggestsToRecreateMainMenu:self];
}

- (void)setChapterFromMenuItem:(NSMenuItem *)sender
{
    [[[self mediaListPlayer] mediaPlayer] setCurrentChapterIndex:[sender tag]];
    [[VLCDocumentController sharedDocumentController] documentSuggestsToRecreateMainMenu:self];
}

- (void)setTitleFromMenuItem:(NSMenuItem *)sender
{
    [[[self mediaListPlayer] mediaPlayer] setCurrentTitleIndex:[sender tag]];
    [[VLCDocumentController sharedDocumentController] documentSuggestsToRecreateMainMenu:self];
}

@end
