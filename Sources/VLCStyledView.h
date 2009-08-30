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

#import <WebKit/WebKit.h>

/* This is a base class that should only be subclassed.
 * It contains the shared code between VLCStyledVideoWindowView
 * and VLCStyledFullscreenHUDWindowView */

@class VLCTime;
@class VLCMediaPlayer;

@interface VLCStyledView : WebView {
    BOOL _isFrameLoaded;
    float _viewedPosition;
    BOOL _viewedPlaying;
    BOOL _seekable;
    
    VLCTime *_currentTime;
    NSString *_title;

    NSString *_pluginName;
}

/**
 * This is overrided, but make sure to call super.
 * Generally you call this from awakeFromNib.
 */
- (void)setup;

/**
 * Subclass have to override this, and provide their content url.
 */
- (NSString *)pageName;

/**
 * Called when the webview is loaded.
 */
- (void)didFinishLoadForFrame:(WebFrame *)frame;

@property (readonly) BOOL isFrameLoaded;

/**
 * DOM manipulation: Add and remove a className from
 * the element that have the id="content".
 *
 * This is used to indicate various state changes.
 */
- (void)addClassToContent:(NSString *)className;
- (void)removeClassFromContent:(NSString *)className;
- (DOMHTMLElement *)htmlElementForId:(NSString *)idName;

/**
 * This will be used to bind some value in the DOM
 */
@property (copy) VLCTime *currentTime;
@property (copy) NSString *windowTitle;
@property float viewedPosition;
@property BOOL viewedPlaying;

- (VLCMediaPlayer *)mediaPlayer;

@end
