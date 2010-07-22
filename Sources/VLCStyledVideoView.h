//
//  VLCStyledVideoView.h
//  Lunettes
//
//  Created by Pierre d'Herbemont on 2/9/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <WebKit/WebKit.h>
#import <VLCKit/VLCKit.h>
#import "VLCStyledView.h"

@interface VLCStyledVideoView : VLCStyledView {
    NSUInteger _listCount;
    NSUInteger _sublistCount;
    NSString *_listCountString;
    NSString *_title;

    VLCMediaPlayerState _mediaPlayerState;

    BOOL _viewedPlaying;
    BOOL _seekable;
    BOOL _showPlaylist;
}

@property (copy) NSString *windowTitle;
@property (copy) NSString *listCountString;
@property BOOL viewedPlaying;
@property BOOL seekable;
@property NSUInteger listCount;
@property NSUInteger sublistCount;
@property BOOL showPlaylist;
@property VLCMediaPlayerState mediaPlayerState;

- (VLCMediaPlayer *)mediaPlayer;
- (VLCMediaListPlayer *)mediaListPlayer;

@end
