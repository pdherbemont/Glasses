//
//  VLCSplashScreenWindowController.m
//  Lunettes
//
//  Created by Pierre d'Herbemont on 8/27/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "VLCSplashScreenWindowController.h"


@implementation VLCSplashScreenWindowController
@synthesize releasedWhenClosed=_releasedWhenClosed;

- (NSString *)windowNibName
{
    return @"SplashScreenWindow";
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    [[self window] center];
}

- (IBAction)reportBug:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://trac.videolan.org"]];
}
@end
