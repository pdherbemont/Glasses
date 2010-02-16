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

/* This is a view that is the content for VLCStyledVideoWindow.
 * VLCStyledVideoWindow is a borderless window that just display,
 * this view.
 *
 * This view is a subclass of WebView, and its goal is to display
 * a window that is entirely html/css/js based.
 *
 * This makes the window easily styleable, so is its content.
 * Hence VLCStyledVideoWindowView supports multiple style.
 *
 * BRIDGING
 * The js code can access both this view and its associated
 * window by window.PlatformWindowController
 * (for VLCStyledVideoWindowController)
 * and window.PlatformView (for VLCStyledVideoWindowView).
 *  window.PlatformWindowController.window returns a VLCStyledVideoWindow.
 * A list of methods that are accessible by javascript are defined
 * in those classes method +isSelectorExcludedFromWebScript:.
 *
 * For instance Window resize and Window drag are handled
 * via javascript code, that directly calls window.PlatformWindow.
 *
 * We also drives the DOM and replaces the timeline, the ellapsed time
 * and we add a className on the #content element to reflect both
 * the window state, and the media player state.
 *
 * The video view is inserted on top of the <div id="video-view">.
 * Its rect is being updated by a callback called -videoViewResized.
 */

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "VLCStyledVideoView.h"

@interface VLCStyledVideoWindowView : VLCStyledVideoView
{
    NSTrackingArea *_contentTracking;

    /**
     * We keep the videoView in a superview, hence
     * when transiting to fullscreen, we can keep all the
     * bounds changes. They will be applied to _containerForVideoView
     * instead of videoView */
    NSView *_containerForVideoView;

#ifdef SUPPORT_VIDEO_BELOW_CONTENT
    NSWindow *_videoWindow;
#endif

    BOOL _isStyleOpaque;
}

- (void)setKeyWindow:(BOOL)isKeyWindow;
- (void)setMainWindow:(BOOL)isMainWindow;

#ifdef SUPPORT_VIDEO_BELOW_CONTENT
- (void)windowDidChangeAlphaValue:(CGFloat)alpha;
#endif

- (NSRect)representedWindowRect;
@end
