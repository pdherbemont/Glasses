/*****************************************************************************
 * Copyright (C) 2009 the VideoLAN team
 *
 * Authors:Pierre d'Herbemont
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

#import "VLCFullscreenController.h"

#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_5
#import <Carbon/Carbon.h> //SystemUIMode
#endif

static const float windowFadingDuration = 0.3;
static const float windowScalingDuration = 0.3;

static inline BOOL debugFullscreen(void)
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kDebugFullscreen];
}

NSInteger VLCFullscreenWindowLevel(void)
{
    return debugFullscreen() ? 0 : 3;
}

NSInteger VLCFullscreenHUDWindowLevel(void)
{
    return debugFullscreen() ? 0 : 4;
}

static float slowMotionCoef(void)
{
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    if ([NSEvent respondsToSelector:@selector(modifierFlags)] && ([NSEvent modifierFlags] & NSShiftKeyMask))
        return 5;
#endif
    return 1;
}

static NSViewAnimation *createViewAnimationWithDefaultsSettingsAndDictionary(NSDictionary *dict)
{
    NSViewAnimation *animation = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObject:dict]];
    [animation setAnimationBlockingMode:NSAnimationNonblocking];
    [animation setFrameRate:60];
    return animation;
}

enum fade_e {
    FadeIn,
    FadeOut
};

static NSViewAnimation *createFadeAnimation(NSWindow *target, enum fade_e fade)
{
    NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:
        target, NSViewAnimationTargetKey,
        fade == FadeIn ? NSViewAnimationFadeInEffect : NSViewAnimationFadeOutEffect, NSViewAnimationEffectKey,
        nil
    ];
    NSViewAnimation *animation = createViewAnimationWithDefaultsSettingsAndDictionary(dict);
    [animation setDuration:windowFadingDuration * slowMotionCoef()];
    [dict release];
    return animation;
}

static NSViewAnimation *createScaleAnimation(NSWindow *target, const NSRect startRect, const NSRect endRect)
{
    NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:
        target, NSViewAnimationTargetKey,
        [NSValue valueWithRect:startRect], NSViewAnimationStartFrameKey,
        [NSValue valueWithRect:endRect], NSViewAnimationEndFrameKey,
        nil
    ];
    NSViewAnimation *animation = createViewAnimationWithDefaultsSettingsAndDictionary(dict);
    [animation setDuration:windowScalingDuration * slowMotionCoef()];
    [dict release];
    return animation;
}


static NSRect screenRectForView(NSView *view)
{
    NSRect screenRect = [[view superview] convertRect:[view frame] toView:nil]; // Convert to Window base coord
    NSRect windowFrame = [[view window] frame];
    screenRect.origin.x += windowFrame.origin.x;
    screenRect.origin.y += windowFrame.origin.y;
    return screenRect;
}

static CGDisplayFadeReservationToken fadeScreens(void)
{
    CGDisplayFadeReservationToken token;
    CGAcquireDisplayFadeReservation(kCGMaxDisplayReservationInterval, &token);
    CGDisplayFade(token, 0.5, kCGDisplayBlendNormal, kCGDisplayBlendSolidColor, 0, 0, 0, YES);
    return token;
}

static void unfadeScreens(CGDisplayFadeReservationToken token)
{
    CGDisplayFade(token, 0.3, kCGDisplayBlendSolidColor, kCGDisplayBlendNormal, 0, 0, 0, NO);
    CGReleaseDisplayFadeReservation(token);
}

#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
@interface VLCFullscreenController () <NSAnimationDelegate>
#else
@interface VLCFullscreenController ()
#endif
- (void)_installPlaceholderView;
- (void)_restoreViewFromPlaceholderView;
- (void)_stopAnimationsIfNeeded;
- (NSWindow *)_windowToHide;

@property (readwrite, assign) BOOL fullscreen;
@end

@implementation VLCFullscreenController
@synthesize fullscreen=_fullscreen;
@synthesize hud=_hud;
@synthesize delegate=_delegate;

- (id)initWithView:(NSView *)view
{
    self = [super init];
    if (!self)
        return nil;
    _originalViewWindow = [[view window] retain];
    _view = [view retain];
    return self;
}

- (void)dealloc
{
    VLCAssert(!_animation1 && !_animation2, @"There should be no animation running at this point");
    [_placeholderView release];
    [_fullscreenWindow release];
    [_originalViewWindow release];
    [_view release];
    [_hud release];
    [super dealloc];
}

- (void)fullscreenDidStart
{
    [_hud fullscreenController:self didEnterFullscreen:[_fullscreenWindow screen]];
    [NSCursor setHiddenUntilMouseMoves:YES];
}

- (void)enterFullscreen:(NSScreen *)screen
{
    // We are already in fullscreen (or going fullscreen)
    if (_fullscreen)
        return;
    self.fullscreen = YES;

    if (!screen)
        screen = [[_view window] screen];
    if (!screen)
        screen = [NSScreen deepestScreen];

    // Only create the _fullscreenWindow if we are not in the middle of the zooming animation.
    if (!_fullscreenWindow) {
        // We can't change the styleMask of an already created NSWindow,
        // so we create an other window, and do eye catching stuff

        NSRect screenRect = screenRectForView(_view);

        // Create the window now.
        _fullscreenWindow = [[NSWindow alloc] initWithContentRect:screenRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES];
        [_fullscreenWindow setBackgroundColor:[NSColor blackColor]];
        [_fullscreenWindow setLevel:VLCFullscreenHUDWindowLevel()];
        [_fullscreenWindow setOpaque:YES];

        if (![_originalViewWindow isVisible] || [_originalViewWindow alphaValue] == 0.0) {
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
            [NSApp setPresentationOptions:NSApplicationPresentationAutoHideDock | NSApplicationPresentationAutoHideMenuBar];
#else
            SetSystemUIMode( kUIModeAllHidden, kUIOptionAutoShowMenuBar);
#endif

            // We don't animate if the view to move fullscreen is not visible, instead we
            // simply fade the display
            CGDisplayFadeReservationToken token = fadeScreens();

            [_fullscreenWindow setFrame:[screen frame] display:NO];
            [self _installPlaceholderView];
            [_fullscreenWindow makeKeyAndOrderFront:self];

            unfadeScreens(token);

            [self fullscreenDidStart];
            return;
        }

        // Make sure we don't see the _view disappearing of the screen during this operation
        NSDisableScreenUpdates();
        [self _installPlaceholderView];
        [_fullscreenWindow makeKeyAndOrderFront:self];
        NSEnableScreenUpdates();
    }

    [self _stopAnimationsIfNeeded];

#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    [NSApp setPresentationOptions:NSApplicationPresentationAutoHideDock | NSApplicationPresentationAutoHideMenuBar];
#else
    SetSystemUIMode( kUIModeAllHidden, kUIOptionAutoShowMenuBar);
#endif

    VLCAssert(!_animation1 && !_animation2, @"There should not be any animation from now");
    _animation1 = createFadeAnimation([self _windowToHide], FadeOut);
    _animation2 = createScaleAnimation(_fullscreenWindow, [_fullscreenWindow frame], [screen frame]);

    [_animation2 setDelegate:self];
    [_animation2 startWhenAnimation:_animation1 reachesProgress:1.0];
    [_animation1 startAnimation];
}

- (void)fullscreenDidEnd
{
    /* This function is private and should be only triggered at the end of the fullscreen change animation */
    /* Make sure we don't see the _view disappearing of the screen during this operation */
    NSDisableScreenUpdates();
    [self _restoreViewFromPlaceholderView];
    [_fullscreenWindow orderOut:self];
    [_view display]; // Make sure the view will be updated. (saves a flash)
    NSEnableScreenUpdates();

    [_fullscreenWindow release];
    _fullscreenWindow = nil;

    [_delegate fullscreenControllerDidLeaveFullscreen:self];

    // See -leaveFullscreenAndFadeOut:
    [self release];
}

- (void)leaveFullscreenAndFadeOut:(BOOL)fadeout
{
    // We are already exiting fullscreen
    if (!_fullscreen)
        return;

    self.fullscreen = NO;

    [_hud fullscreenControllerWillLeaveFullscreen:self];

    // Show the Dock and the Menu Bar
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    [NSApp setPresentationOptions:NSApplicationPresentationDefault];
#else
    SetSystemUIMode( kUIModeNormal, kUIOptionAutoShowMenuBar);
#endif

    VLCAssert(_fullscreenWindow, @"There should be a fullscreen Window at this time");

    // This might happen if we quickly exit fullscreen and release us.
    // Balanced in -fullscreenDidEnd
    [self retain];

    if (fadeout) {
        CGDisplayFadeReservationToken token = fadeScreens();
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
        [NSApp setPresentationOptions:NSApplicationPresentationDefault];
#else
        SetSystemUIMode( kUIModeNormal, kUIOptionAutoShowMenuBar);
#endif
        [self fullscreenDidEnd];
        unfadeScreens(token);
        return;
    }

    [self _stopAnimationsIfNeeded];

    NSRect screenRect = screenRectForView(_placeholderView);

    VLCAssert(!_animation1 && !_animation2, @"There should not be any animation from now");
    _animation1 = createScaleAnimation(_fullscreenWindow, [_fullscreenWindow frame], screenRect);
    _animation2 = createFadeAnimation([self _windowToHide], FadeIn);

    NSWindow *windowToHide = [self _windowToHide];

    [_fullscreenWindow makeKeyAndOrderFront:nil];
    [windowToHide orderWindow:NSWindowBelow relativeTo:[_fullscreenWindow windowNumber]];
    [windowToHide makeMainWindow];
    [windowToHide makeKeyWindow];


    [_animation2 setDelegate:self];
    [_animation2 startWhenAnimation:_animation1 reachesProgress:1.0];
    [_animation1 startAnimation];
}

- (void)leaveFullscreen
{
    [self leaveFullscreenAndFadeOut:NO];
}


- (void)animationDidEnd:(NSAnimation *)animation
{
    VLCAssert(animation == _animation2, @"We should only be the delegate from _animation2");
    if ([animation currentValue] < 1.0)
        return;

    // Just clear all the animations.
    [self _stopAnimationsIfNeeded];

    // Fullscreen ended or started (we are a delegate only for leaveFullscreen's/enterFullscren's anim2)
    if (self.fullscreen)
        [self fullscreenDidStart];
    else
        [self fullscreenDidEnd];
}


// This method must only be used from -enterFullscreen
- (void)_installPlaceholderView
{
    VLCAssert(!_placeholderView, @"There shouldn't be a place holder view at this time");
    _placeholderView = [[NSView alloc] init];
    [_placeholderView setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];
    VLCAssert([_view superview], @"This view has no superview, this means that we won't be able to re-attach it.");
    [[_view superview] replaceSubview:_view with:_placeholderView];
    [_placeholderView setFrame:[_view frame]];
    [_fullscreenWindow setContentView:_view];
}

- (void)_restoreViewFromPlaceholderView
{
    VLCAssert(_placeholderView, @"There should be a place holder view at this time");
    [[_placeholderView superview] replaceSubview:_placeholderView with:_view];
    [_view setFrame:[_placeholderView frame]];
    [_placeholderView release];
    _placeholderView = nil;
}

- (void)_stopAnimationsIfNeeded
{
    if (_animation1 || _animation2) {
        VLCAssert(_animation1 && _animation2, @"The two animations should have the same life cycle");
        [_animation1 stopAnimation];
        [_animation2 stopAnimation];
        [_animation1 release];
        [_animation2 release];
        _animation1 = nil;
        _animation2 = nil;
    }
}

- (NSWindow *)_windowToHide
{
    return [_originalViewWindow parentWindow] ?: _originalViewWindow;
}
@end
