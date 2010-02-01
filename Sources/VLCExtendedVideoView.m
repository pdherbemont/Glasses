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

#import "VLCExtendedVideoView.h"
#import "NSScreen_Additions.h"

@interface VLCExtendedVideoView ()
- (void)mediaPlayerStateChanged:(NSNotification *)aNotification;
@end

@implementation VLCExtendedVideoView

- (VLCMediaPlayer *)mediaPlayer
{
    return _mediaPlayer;
}

- (void)setMediaPlayer:(VLCMediaPlayer *) mp
{
    if (_mediaPlayer == mp)
        return;
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    if (_mediaPlayer)
        [center removeObserver:self name:VLCMediaPlayerStateChanged object:_mediaPlayer];

    _mediaPlayer = mp;
    [center addObserver:self selector:@selector(mediaPlayerStateChanged:) name:VLCMediaPlayerStateChanged object:_mediaPlayer];

    // Force an update of the errorView
    [self mediaPlayerStateChanged:nil];
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (BOOL)mouseDownCanMoveWindow
{
    return YES;
}

- (BOOL)isOpaque
{
    return YES;
}

- (void)scrollWheel:(NSEvent *)event
{
    CGFloat deltaY = [event deltaY];
    if (fabs(deltaY) < 0.05)
        return;
    VLCAudio *audio = [[self mediaPlayer] audio];

    NSInteger volume = [audio volume] + deltaY;
    if (volume < 0)
        volume = 0;
    [audio setVolume:volume];
}

- (void)mediaPlayerStateChanged:(NSNotification *)aNotification
{
    if ([_mediaPlayer state] == VLCMediaPlayerStateError) {
        if (!_errorView) {
            _errorView = [[NSImageView alloc] initWithFrame:[self bounds]];
            NSImage * errorImage = [NSImage imageNamed:@"errorImage"];
            [_errorView setImage:errorImage];
            [_errorView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
            [self addSubview:_errorView];
        }

        // Small hack to remove the hide the glView during error.
        for (NSView *view in [self subviews]) {
            if (view != _errorView)
                [view setHidden:YES];
        }
    }
    else {
        [_errorView removeFromSuperview];
        [_errorView release];
        _errorView = nil;
        for (NSView *view in [self subviews]) {
            [view setHidden:NO];
        }
    }

}


- (void)dealloc
{
    [_errorView release];
    if (_mediaPlayer)
        [[NSNotificationCenter defaultCenter] removeObserver:self name:VLCMediaPlayerStateChanged object:_mediaPlayer];
    [super dealloc];
}
@end
