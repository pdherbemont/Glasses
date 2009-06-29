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

#import "VLCDetachableViewPlaceholder.h"
#import "NSScreen_Additions.h"

@implementation VLCDetachableViewPlaceholder
@synthesize videoView=_videoView;
@synthesize mediaDocument=_mediaDocument;

- (id)initWithFrame:(NSRect)frame
{
	if((self = [super initWithFrame:frame]))
	{
		_childWindow = [[NSWindow alloc] initWithContentRect:frame styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
		[_childWindow setIgnoresMouseEvents:YES];
	}
	return self;
}

- (void)dealloc
{
	[_window release];
	[super dealloc];
}

#pragma mark -

- (void)setVideoView:(VLCExtendedVideoView *)videoView
{
	_videoView.placeholder = nil;
	[_videoView release];
	_videoView = [videoView retain];
	_videoView.placeholder = self;
	[_childWindow setContentView:_videoView];

	[[self window] addChildWindow:_childWindow ordered:NSWindowAbove];
	[[self window] makeKeyAndOrderFront:self];
	[_childWindow setFrameOrigin: [[self window] convertBaseToScreen:[self frame].origin]];
	[_childWindow makeKeyAndOrderFront:self];
}


- (void)toggleFullscreen
{
	if(!_isFullscreen) {
		NSScreen * screen = [[self window] screen];
		if ([screen isMainScreen])
			[NSMenu setMenuBarVisible:NO];
		
		[_childWindow setIgnoresMouseEvents:NO];
		[_childWindow setFrame:[screen frame] display:YES animate:YES];
		[self.mediaDocument.fullscreenHUDWindowController activate];
	}
	else {
		[NSMenu setMenuBarVisible:YES];
		[self.mediaDocument.fullscreenHUDWindowController deactivate];

		[_childWindow setIgnoresMouseEvents:YES];
		NSRect frame = [self frame];
		frame.origin = [[self window] convertBaseToScreen:frame.origin];
		[_childWindow setFrame:frame display:YES animate:YES];
	}
	_isFullscreen = !_isFullscreen;
}

#pragma mark -
- (void)setFrame:(NSRect)frame
{
	[super setFrame:frame];
	frame.origin = [[self window] convertBaseToScreen:frame.origin];
	[_childWindow setFrame:frame display:YES];
}

- (void)mouseDown:(NSEvent *)event
{
	if ([event clickCount] == 2) {		
		[self toggleFullscreen];
	}
}
@end
