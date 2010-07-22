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

/* Helper when calling a function from JS.
 * Those have two uses:
 * 1. Set up an autorelease pool for finer grain memory control
 * 2. Set up an exception handler to actually handle the exception */

#define CATCH_EXCEPTION \
    } @catch (NSException *e) { \
        (*NSGetUncaughtExceptionHandler())(e); \
    } @finally { \
        [pool drain]; \
    }

#define FROM_JS() \
    id __ret = nil; (void)__ret; \
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; \
    @try {

#define RETURN_NOTHING_TO_JS() \
    CATCH_EXCEPTION

#define RETURN_VALUE_TO_JS(a) \
CATCH_EXCEPTION return a;

#define RETURN_OBJECT_TO_JS(a) \
    __ret = [a retain]; \
    CATCH_EXCEPTION \
    return [__ret autorelease]; \

#define DIRECTLY_RETURN_OBJECT_TO_JS(a) \
    FROM_JS(); RETURN_OBJECT_TO_JS(a)

#define DIRECTLY_RETURN_VALUE_TO_JS(a) \
    FROM_JS(); return a; CATCH_EXCEPTION return 0;

/* This is a base class that should only be subclassed.
 * It contains the shared code between VLCStyledVideoWindowView
 * and VLCStyledFullscreenHUDWindowView */

@class VLCPathWatcher;
@class VLCWebBindingsController;

@interface VLCStyledView : WebView {
    NSString *_lunettesStyleRoot;
    NSMutableArray *_resourcesFilePathArray;
    NSString *_pluginName;

    VLCPathWatcher *_pathWatcher;
    VLCWebBindingsController *_bindings;

    BOOL _isFrameLoaded;
    BOOL _hasLoadedAFirstFrame;
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
- (void)setInnerText:(NSString *)text forElementsOfClass:(NSString *)className;

@end
