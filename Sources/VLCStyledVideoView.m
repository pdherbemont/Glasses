//
//  VLCStyledVideoView.m
//  Lunettes
//
//  Created by Pierre d'Herbemont on 2/9/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "VLCStyledVideoView.h"
#import "VLCMediaDocument.h"

@implementation VLCStyledVideoView
@synthesize listCountString=_listCountString;
- (void)dealloc
{
    [_title release];
    [_listCountString release];
    [super dealloc];
}

- (void)didFinishLoadForFrame:(WebFrame *)frame
{
    [super didFinishLoadForFrame:frame];

    NSWindow *window = [self window];
    [self setWindowTitle:[window title]];
    [self setViewedPlaying:_viewedPlaying];
    [self setSeekable:_seekable];
    [self setListCount:_listCount];
    [self setSublistCount:_sublistCount];
    [self setMediaPlayerState:_mediaPlayerState];

    // Tell our Document that we are now ready and initialized.
    // This is to make sure that we play only once the webview is loaded.
    // This way we wont overload the CPU, during opening.
    if (!self.hasLoadedAFirstFrame) {
        NSWindowController *controller = [[self window] windowController];
        [[controller document] didFinishLoadingWindowController:controller];
    }
}

- (void)setPosition:(float)position
{
    FROM_JS();
    VLCMediaPlayer *player = [self mediaPlayer];
    if (![player isPlaying])
        [player play];
    [player setPosition:position];
    [[[[self window] windowController] document] playbackPositionChanged];
    RETURN_NOTHING_TO_JS();
}

- (void)play
{
    FROM_JS();
    [[self mediaPlayer] play];
    RETURN_NOTHING_TO_JS();
}

- (void)pause
{
    FROM_JS();
    [[self mediaPlayer] pause];
    RETURN_NOTHING_TO_JS();
}

- (BOOL)isSeekable
{
    DIRECTLY_RETURN_VALUE_TO_JS([[self mediaPlayer] isSeekable]);
}

- (VLCMediaListPlayer *)mediaListPlayer
{
    DIRECTLY_RETURN_OBJECT_TO_JS([[[[self window] windowController] document] mediaListPlayer]);
}

- (VLCMediaPlayer *)mediaPlayer
{
    DIRECTLY_RETURN_OBJECT_TO_JS([[[[self window] windowController] document] mediaListPlayer].mediaPlayer);
}

- (VLCMediaList *)rootMediaList
{
    DIRECTLY_RETURN_OBJECT_TO_JS([[[[self window] windowController] document] rootMediaList]);
}

- (NSUInteger)count
{
    DIRECTLY_RETURN_VALUE_TO_JS([[self rootMediaList] count]);
}

- (void)playCocoaObject:(WebScriptObject *)object
{
    FROM_JS();
    [[self mediaListPlayer] playMedia:[object valueForKey:@"backendObject"]];
    RETURN_NOTHING_TO_JS();
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)sel
{
    if (sel == @selector(count))
        return NO;
    if (sel == @selector(play))
        return NO;
    if (sel == @selector(pause))
        return NO;
    if (sel == @selector(setPosition:))
        return NO;
    if (sel == @selector(isSeekable))
        return NO;
    if (sel == @selector(playCocoaObject:))
        return NO;
    return [super isSelectorExcludedFromWebScript:sel];
}

+ (NSString *)webScriptNameForSelector:(SEL)sel
{
    if (sel == @selector(playCocoaObject:))
        return @"playCocoaObject";
    return [super webScriptNameForSelector:sel];
}

#pragma mark -
#pragma mark Core -> Javascript setters

- (void)setMediaPlayerState:(VLCMediaPlayerState)state
{
    _mediaPlayerState = state;

    if (![self isFrameLoaded])
        return;

    if (state == VLCMediaPlayerStateError)
        [self addClassToContent:@"media-player-error"];
    else
        [self removeClassFromContent:@"media-player-error"];
}

- (VLCMediaPlayerState)mediaPlayerState
{
    return _mediaPlayerState;
}

- (void)setWindowTitle:(NSString *)title
{
    if (_title != title) {
        [_title release];
        _title = [title copy];
    }
    if (!_isFrameLoaded)
        return;
    [self setInnerText:title forElementsOfClass:@"title"];
}

- (NSString *)windowTitle
{
    return _title;
}

- (void)setViewedPlaying:(BOOL)isPlaying
{
    _viewedPlaying = isPlaying;
    if (!_isFrameLoaded)
        return;
    if (isPlaying)
        [self addClassToContent:@"playing"];
    else
        [self removeClassFromContent:@"playing"];
}

- (BOOL)viewedPlaying
{
    return _viewedPlaying;
}

- (void)setSeekable:(BOOL)isSeekable
{
    _seekable = isSeekable;
    if (!_isFrameLoaded)
        return;
    if (isSeekable)
        [self addClassToContent:@"seekable"];
    else
        [self removeClassFromContent:@"seekable"];

}

- (BOOL)seekable
{
    return _seekable;
}

- (void)setHTMLListCount:(NSUInteger)count
{
    DOMHTMLElement *element = [self htmlElementForId:@"items-count" canBeNil:YES];
    [element setInnerText:[NSString stringWithFormat:@"%d", count]];

    [self setListCountString:[NSString stringWithFormat:@"%d item%s", count, count > 1 ? "s" : ""]];
    if (count == 1)
        [self removeClassFromContent:@"multiple-play-items"];
    else
        [self addClassToContent:@"multiple-play-items"];
}

- (void)setListCount:(NSUInteger)count
{
    _listCount = count;

    // Use the sublist count if we have subitems.
    if (_sublistCount > 0)
        return;

    [self setHTMLListCount:count];
}

- (NSUInteger)listCount
{
    return _listCount;
}

- (void)setSublistCount:(NSUInteger)count
{
    _sublistCount = count;

    // No subitems, use the list count.
    if (_sublistCount == 0)
        return;

    [self setHTMLListCount:count];
}

- (NSUInteger)sublistCount
{
    return _sublistCount;
}

- (void)setShowPlaylist:(BOOL)show
{
    _showPlaylist = show;
}

- (BOOL)showPlaylist
{
    return _showPlaylist;
}

@end
