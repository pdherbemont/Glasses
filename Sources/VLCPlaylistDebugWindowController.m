//
//  VLCPlaylistWindowController.m
//  Lunettes
//
//  Created by Pierre d'Herbemont on 8/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "VLCPlaylistDebugWindowController.h"
#import "VLCMediaDocument.h"


@implementation VLCPlaylistDebugWindowController

- (NSString *)windowNibName
{
    return @"PlaylistDebugWindow";
}

- (IBAction)playSelectedItem:(id)sender
{
    VLCAssert(_playlistTreeController, @"No tree controller in the xib file");

    NSArray *selectedObjects = [_playlistTreeController selectedObjects];
    if ([selectedObjects count] <= 0)
        return;
    VLCMediaListPlayer *player = [self.document mediaListPlayer];
    [player playMedia:[selectedObjects objectAtIndex:0]];
}

@end
