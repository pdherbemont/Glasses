//
//  VLCVideoWindowController.h
//  Glasses
//
//  Created by Pierre d'Herbemont on 8/22/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class VLCExtendedVideoView;

@interface VLCVideoWindowController : NSWindowController {
    IBOutlet VLCExtendedVideoView *_videoView;
	IBOutlet NSButton *_playPauseButton;
}

@property (readonly, retain) VLCExtendedVideoView *videoView;

- (IBAction)togglePlayPause:(id)sender;
- (IBAction)toggleFullscreen:(id)sender;

@end
