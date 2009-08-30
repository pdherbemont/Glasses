//
//  VLCPlaylistWindowController.h
//  Lunettes
//
//  Created by Pierre d'Herbemont on 8/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface VLCPlaylistDebugWindowController : NSWindowController {
    IBOutlet NSTreeController *_playlistTreeController;
}

- (IBAction)playSelectedItem:(id)sender;

@end
