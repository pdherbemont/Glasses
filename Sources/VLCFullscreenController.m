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

const NSInteger VLCFullscreenWindowLevel = 0; // NSFloatingWindowLevel
const NSInteger VLCFullscreenHUDWindowLevel = 0;  // NSFloatingWindowLevel + 1

#import <Carbon/Carbon.h> // For SetSystemUIMode

static NSViewAnimation *createViewAnimationWithDefaultsSettingsAndDictionary(NSDictionary *dict)
{
    NSViewAnimation *animation = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObject:dict]];
    [animation setAnimationBlockingMode:NSAnimationNonblocking];
    [animation setDuration:0.3];
    [animation setFrameRate:30];
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
        fade == FadeIn ? NSViewAnimationFadeInEffect :NSViewAnimationFadeOutEffect, NSViewAnimationEffectKey,
        nil
    ];
    NSViewAnimation *animation = createViewAnimationWithDefaultsSettingsAndDictionary(dict);
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


@interface VLCFullscreenController ()
- (void)_installPlaceholderView;
- (void)_restoreViewFromPlaceholderView;
- (void)_stopAnimationsIfNeeded;
@property (readwrite, assign) BOOL fullscreen;
@end

@implementation VLCFullscreenController
@synthesize fullscreen=_fullscreen;
@synthesize hud=_hud;

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
    NSAssert(!_animation1 && !_animation2, @"There should be no animation running at this point");
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

    [NSCursor setHiddenUntilMouseMoves:YES];

    // Only create the _fullscreenWindow if we are not in the middle of the zooming animation.
    if (!_fullscreenWindow) {
        // We can't change the styleMask of an already created NSWindow,
        // so we create an other window, and do eye catching stuff
        
        NSRect screenRect = screenRectForView(_view);
        
        // Create the window now.
        _fullscreenWindow = [[NSWindow alloc] initWithContentRect:screenRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES];
        [_fullscreenWindow setBackgroundColor:[NSColor blackColor]];
        [_fullscreenWindow setLevel:VLCFullscreenHUDWindowLevel];

        if (![_originalViewWindow isVisible] || [_originalViewWindow alphaValue] == 0.0) {
            // We don't animate if the view to move fullscreen is not visible, instead we
            // simply fade the display
            CGDisplayFadeReservationToken token = fadeScreens();

            SetSystemUIMode( kUIModeAllHidden, kUIOptionAutoShowMenuBar);
            [self _installPlaceholderView];
            [_fullscreenWindow setFrame:[screen frame] display:NO];
            [_fullscreenWindow makeKeyAndOrderFront:self];

            unfadeScreens(token);

            [self fullscreenDidStart];
            return;
        }
        
        // Make sure we don't see the _view disappearing of the screen during this operation
        NSDisableScreenUpdates();
        [self _installPlaceholderView];
        [_fullscreenWindow setContentView:_view];
        [_fullscreenWindow makeKeyAndOrderFront:self];
        NSEnableScreenUpdates();
    }

    [self _stopAnimationsIfNeeded];

    SetSystemUIMode( kUIModeAllHidden, kUIOptionAutoShowMenuBar);

    _animation1 = createFadeAnimation(_originalViewWindow, FadeOut);
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
    NSEnableScreenUpdates();
    
    [_fullscreenWindow release];
    _fullscreenWindow = nil;
}

- (void)leaveFullscreenAndFadeOut:(BOOL)fadeout
{
    // We are already exiting fullscreen
    if (!_fullscreen)
        return;
    self.fullscreen = NO;

    [_hud fullscreenControllerWillLeaveFullscreen:self];

    NSAssert(_fullscreenWindow, @"There should be a fullscreen Window at this time");
    
    if (fadeout) {
        CGDisplayFadeReservationToken token = fadeScreens();
        SetSystemUIMode( kUIModeNormal, kUIOptionAutoShowMenuBar);
        [self fullscreenDidEnd];
        unfadeScreens(token);
        return;
    }

    [self _stopAnimationsIfNeeded];
    
    SetSystemUIMode(kUIModeNormal, kUIOptionAutoShowMenuBar);

    NSRect screenRect = screenRectForView(_placeholderView);

    _animation1 = createFadeAnimation(_originalViewWindow, FadeOut);
    _animation2 = createScaleAnimation(_fullscreenWindow, [_fullscreenWindow frame], screenRect);

    [_animation1 setDelegate:self];
    [_animation1 startWhenAnimation:_animation2 reachesProgress:1.0];
    [_animation2 startAnimation];
}

- (void)leaveFullscreen
{
    [self leaveFullscreenAndFadeOut:NO];
}


- (void)animationDidEnd:(NSAnimation*)animation
{
    NSAssert(animation == _animation2, @"We should only be the delegate from _animation2");
    if ([animation currentValue] < 1.0)
        return;
    
    // Fullscreen ended or started (we are a delegate only for leaveFullscreen's/enterFullscren's anim2)
    if (self.fullscreen)
        [self fullscreenDidStart];
    else
        [self fullscreenDidEnd];
}


// This method must only be used from -enterFullscreen
- (void)_installPlaceholderView
{
    NSAssert(!_placeholderView, @"There shouldn't be a place holder view at this time");
    _placeholderView = [[NSView alloc] init];
    [[_view superview] replaceSubview:_view with:_placeholderView];
    [_placeholderView setFrame:[_view frame]];
    [_fullscreenWindow setContentView:_view];    
}

- (void)_restoreViewFromPlaceholderView
{
    NSAssert(_placeholderView, @"There should be a place holder view at this time");
    [_view removeFromSuperviewWithoutNeedingDisplay];
    [[_placeholderView superview] replaceSubview:_placeholderView with:_view];
    [_view setFrame:[_placeholderView frame]];
    [_placeholderView release];
    _placeholderView = nil;
}

- (void)_stopAnimationsIfNeeded
{
    if (_animation1 || _animation2) {
        NSAssert(_animation1 && _animation2, @"The two animations should have the same life cycle");
        [_animation1 stopAnimation];
        [_animation2 stopAnimation];
        [_animation1 release];
        [_animation2 release];
        _animation1 = nil;
        _animation2 = nil;
    }    
}
@end
