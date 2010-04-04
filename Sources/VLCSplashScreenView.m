//
//  VLCSplashScreenView.m
//  Lunettes
//
//  Created by Pierre d'Herbemont on 2/1/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "VLCSplashScreenView.h"
#import "VLCSplashScreenWindowController.h"
#import "VLCDocumentController.h"

@implementation VLCSplashScreenView
@synthesize currentArrayController=_currentArrayController;

- (NSString *)pageName
{
    return @"splash-screen";
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    if (!self)
        return nil;
    [self setup];
    return self;
}

+ (NSSet *)keyPathsForValuesAffectingMediaDiscovererArrayController
{
    return [NSSet setWithObject:@"window.windowController.mediaDiscovererArrayController"];
}

- (NSDocumentController *)documentController
{
    DIRECTLY_RETURN_OBJECT_TO_JS([NSDocumentController sharedDocumentController]);
}

- (NSArrayController *)mediaDiscovererArrayController
{
    DIRECTLY_RETURN_OBJECT_TO_JS([[[self window] windowController] mediaDiscovererArrayController]);
}

- (NSArrayController *)tvShowsArrayController
{
    DIRECTLY_RETURN_OBJECT_TO_JS([[[self window] windowController] tvShowsArrayController]);
}

- (NSArrayController *)unseenItemsArrayController
{
    DIRECTLY_RETURN_OBJECT_TO_JS([[[self window] windowController] unseenItemsArrayController]);
}

- (NSArrayController *)seenItemsArrayController
{
    DIRECTLY_RETURN_OBJECT_TO_JS([[[self window] windowController] seenItemsArrayController]);
}

- (NSArrayController *)allItemsArrayController
{
    DIRECTLY_RETURN_OBJECT_TO_JS([[[self window] windowController] allItemsArrayController]);
}

- (void)didFinishLoadForFrame:(WebFrame *)frame
{
    [super didFinishLoadForFrame:frame];

    // See the comment in -loadArrayControllers definition.
    // We do it in the next run loop run to make sure we'll still properly
    // display the view first.
    [[[self window] windowController] performSelector:@selector(loadArrayControllers) withObject:nil afterDelay:0];
}

- (void)playCocoaObject:(WebScriptObject *)object
{
    FROM_JS();
    id representedObject = [object valueForKey:@"backendObject"];
    NSString *stringURL = [representedObject valueForKey:@"url"];
    NSURL *url = [NSURL URLWithString:stringURL];
    VLCAssert(url, @"Invalid string in DB!");
    double position = [[representedObject valueForKey:@"lastPosition"] doubleValue];
    [[VLCDocumentController sharedDocumentController] makeDocumentWithURL:url andStartingPosition:position];
    [[[self window] windowController] close];
    RETURN_NOTHING_TO_JS();
}

- (void)playMediaDiscoverer:(WebScriptObject *)mdObject withMedia:(WebScriptObject *)mediaObject
{
    FROM_JS();
    VLCMedia *media = [mediaObject valueForKey:@"backendObject"];
    VLCMediaDiscoverer *mediaDiscoverer = [mdObject valueForKey:@"backendObject"];
    [[VLCDocumentController sharedDocumentController] makeDocumentWithMediaDiscoverer:mediaDiscoverer andMediaToPlay:media];
    [[[self window] windowController] close];
    RETURN_NOTHING_TO_JS();
}


+ (BOOL)isSelectorExcludedFromWebScript:(SEL)sel
{
    if (sel == @selector(playMediaDiscoverer:withMedia:))
        return NO;
    if (sel == @selector(playCocoaObject:))
        return NO;
    return [super isSelectorExcludedFromWebScript:sel];
}

+ (NSString *)webScriptNameForSelector:(SEL)sel
{
    if (sel == @selector(playMediaDiscoverer:withMedia:))
        return @"playMediaDiscovererWithMedia";
    if (sel == @selector(playCocoaObject:))
        return @"playCocoaObject";
    return [super webScriptNameForSelector:sel];
}

- (void)selectAll:(id)sender
{
    NSArrayController *controller = [[VLCDocumentController sharedDocumentController] currentArrayController];
    [controller setSelectedObjects:[controller arrangedObjects]];
}
@end
