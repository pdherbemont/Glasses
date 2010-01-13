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
@class VLCPathWatcher;
@class VLCWebBindingsController;

@interface VLCStyledView : WebView {
    NSUInteger _listCount;
    NSUInteger _sublistCount;
    NSString *_listCountString;

    NSString *_title;

    NSString *_pluginName;

    NSString *_lunettesStyleRoot;
    NSMutableArray *_resourcesFilePathArray;

    VLCPathWatcher *_pathWatcher;
    VLCWebBindingsController *_bindings;

    BOOL _isFrameLoaded;
    BOOL _hasLoadedAFirstFrame;
    BOOL _viewedPlaying;
    BOOL _seekable;
    BOOL _showPlaylist;
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

@property (readwrite, retain) NSString *listCountString;

/**
 * -setup has been called, and we have been loading
 * one first frame.
 */
@property BOOL hasLoadedAFirstFrame;

/**
 * DOM manipulation: Add and remove a className from
 * the element that have the id="content".
 *
 * This is used to indicate various state changes.
 */
- (BOOL)contentHasClassName:(NSString *)className;
- (void)addClassToContent:(NSString *)className;
- (void)removeClassFromContent:(NSString *)className;
- (DOMHTMLElement *)htmlElementForId:(NSString *)idName;
- (DOMHTMLElement *)htmlElementForId:(NSString *)idName canBeNil:(BOOL)canBeNil;

/**
 * This will be used to bind some value in the DOM
 */
@property (copy) NSString *windowTitle;
@property BOOL viewedPlaying;
@property BOOL seekable;
@property NSUInteger listCount;
@property NSUInteger sublistCount;
@property BOOL showPlaylist;

- (VLCMediaPlayer *)mediaPlayer;

@end
