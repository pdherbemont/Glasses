/*****************************************************************************
* Copyright (C) 2009 the VideoLAN team
* $Id:$
*
* Authors:Felix Paul Kühne <fkuehne at videolan dot org>
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

#import "VLCAboutWindowController.h"

#pragma mark -

@interface VLCTextScrollAnimation : NSAnimation {
    NSTextView *_textview;
    BOOL _reverse;
}
@property (retain) NSTextView *textview;
@property BOOL reverse;
@end

@implementation VLCTextScrollAnimation
@synthesize textview=_textview;
@synthesize reverse=_reverse;

- (id)init
{
    self = [super initWithDuration:30. animationCurve:NSAnimationLinear];
    if (!self)
        return nil;

    [self setFrameRate:60.0];
    [self setAnimationBlockingMode:NSAnimationNonblocking];
    
    return self;
}

- (void)setCurrentProgress:(NSAnimationProgress)progress
{
    // Call super to update the progress value.
    [super setCurrentProgress:progress];
    
    CGFloat value = [self currentValue];
    CGFloat realValue = _reverse ? 1 - value : value;
    [_textview scrollPoint:NSMakePoint(0, realValue * _textview.bounds.size.height)];
}

@end

#pragma mark -

@implementation VLCGPLWindowController

- (NSString *)windowNibName
{
    return @"AboutWindow";
}

-(IBAction)showWindow:(id)sender
{
    [_gplTextField setString:[NSString stringWithUTF8String:psz_license]];
    [_gplTextField setFont: [NSFont fontWithName:@"Lucida Grande" size:11.0]];
    NSWindow *window = [self window];
    [window center];
    [window makeKeyAndOrderFront:self];
}

@end

#pragma mark -

@implementation VLCAboutWindowController

- (NSString *)windowNibName
{
    return @"AboutWindow";
}

- (void)awakeFromNib
{
    [[self window] setDelegate:self];
    _gplWindowController = [[VLCGPLWindowController alloc] init];

    /* Get the localized info dictionary (InfoPlist.strings) */
    NSDictionary *localDict = [[NSBundle mainBundle] infoDictionary];

    /* Setup the copyright field */
    [_copyrightField setStringValue:[NSString stringWithFormat:@"%@", [localDict objectForKey:@"NSHumanReadableCopyright"]]];

    /* Setup the nameversion field */
    [_versionField setStringValue:[NSString stringWithFormat:@"Version %@", [localDict objectForKey:@"CFBundleVersion"]]];

    /* setup the authors and thanks field */
    [_creditsTextView setString: [NSString stringWithFormat:@"%@\n%@\n\n%@",
                                  [NSString stringWithUTF8String:psz_genericAbout],
                                  [NSString stringWithUTF8String:psz_authors],
                                  [NSString stringWithUTF8String:psz_thanks]]];
    [_creditsTextView setFont: [NSFont fontWithName:@"Lucida Grande" size:11.0]];

    /* Setup the window */
    [_creditsTextView setDrawsBackground:NO];
    [_creditsScrollView setDrawsBackground:NO];
    [[self window] setExcludedFromWindowsMenu:YES];
    [[self window] setMenu:nil];
    [[self window] center];
}

- (void)dealloc
{
    NSAssert(!_animation, @"Should have been released");
    NSAssert(!_rewindAnimation, @"Should have been released");
    [_gplWindowController release];

    [super dealloc];
}

- (void)stopAnimation
{
    [NSObject cancelPreviousPerformRequestsWithTarget:_animation];
    [_animation stopAnimation];
    [_animation release];
    _animation = nil;
}

- (void)stopAllAnimations
{
    [self stopAnimation];
    [NSObject cancelPreviousPerformRequestsWithTarget:_rewindAnimation];
    [_rewindAnimation stopAnimation];
    [_rewindAnimation release];
    _rewindAnimation = nil;
}

- (void)close
{
    [self stopAllAnimations];
}


- (void)windowDidBecomeKey:(NSNotification *)notification
{    
    NSAssert(!_animation, @"Should have been released");
    _animation = [[VLCTextScrollAnimation alloc] init];
    _animation.textview = _creditsTextView;
    
    [_animation setDelegate:self];
    [_animation performSelector:@selector(startAnimation) withObject:nil afterDelay:3];
}

- (void)windowDidResignKey:(NSNotification *)notification
{
    [self stopAnimation];
}

- (void)launchRewindAnimationWithProgress:(CGFloat)progress
{
    NSAssert(!_rewindAnimation, @"There should be no _rewindAnimation");
    _rewindAnimation = [[VLCTextScrollAnimation alloc] init];
    _rewindAnimation.textview = _creditsTextView;
    _rewindAnimation.reverse = YES;
    
    [_rewindAnimation setDelegate:self];
    [_rewindAnimation setDuration:2];
    [_rewindAnimation setAnimationCurve:NSAnimationEaseInOut];
    if (progress == 1) {
        [_rewindAnimation performSelector:@selector(startAnimation) withObject:nil afterDelay:3];
        return;
    }
    [_rewindAnimation setCurrentProgress:progress];
    [_rewindAnimation startAnimation];    
}

- (void)animationDidStop:(NSAnimation *)animation
{
    if (animation != _animation)
        return;
    CGFloat currentProgress = [_animation currentProgress];
    [self launchRewindAnimationWithProgress:1 - currentProgress];
}

- (void)animationDidEnd:(NSAnimation *)animation
{
    if (animation == _rewindAnimation) {
        [_rewindAnimation release];
        _rewindAnimation = nil;
        return;
    }
    NSAssert(animation == _animation, @"This should be _animation");
    [_animation release];
    _animation = nil;
    [self launchRewindAnimationWithProgress:0];
}

- (IBAction)showWindow:(id)sender
{
    /* Show the window */
    [_creditsTextView scrollPoint:NSMakePoint(0,0)];
    [[self window] makeKeyAndOrderFront:sender];
}

@end


