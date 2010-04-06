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

- (NSArrayController *)clipsArrayController
{
    DIRECTLY_RETURN_OBJECT_TO_JS([[[self window] windowController] clipsArrayController]);
}

- (NSArrayController *)moviesArrayController
{
    DIRECTLY_RETURN_OBJECT_TO_JS([[[self window] windowController] moviesArrayController]);
}

- (NSArrayController *)labelsArrayController
{
    DIRECTLY_RETURN_OBJECT_TO_JS([[[self window] windowController] labelsArrayController]);
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


- (void)addNewLabel
{
    FROM_JS();
    NSString *name = @"Undefined";
    [[VLCDocumentController sharedDocumentController] addNewLabelWithName:name];
    RETURN_NOTHING_TO_JS();
}

- (void)setLabel:(WebScriptObject *)weblabel forMedia:(WebScriptObject *)webmedia
{
    FROM_JS();
    NSManagedObject *label = [weblabel valueForKey:@"backendObject"];
    NSManagedObject *media = [webmedia valueForKey:@"backendObject"];
    if ([media isKindOfClass:[VLCMedia class]]) {
        // Create a new kind
    }
    [[label mutableSetValueForKey:@"files"] addObject:media];
    RETURN_NOTHING_TO_JS();
}

- (void)remove:(WebScriptObject *)webobject
{
    FROM_JS();
    id object = [webobject valueForKey:@"backendObject"];
    [object setValue:@"hidden" forKey:@"type"];
    RETURN_NOTHING_TO_JS();
}


+ (BOOL)isSelectorExcludedFromWebScript:(SEL)sel
{
    if (sel == @selector(playMediaDiscoverer:withMedia:))
        return NO;
    if (sel == @selector(playCocoaObject:))
        return NO;
    if (sel == @selector(addNewLabel))
        return NO;
    if (sel == @selector(remove:))
        return NO;
    if (sel == @selector(setLabel:forMedia:))
        return NO;
    return [super isSelectorExcludedFromWebScript:sel];
}

+ (NSString *)webScriptNameForSelector:(SEL)sel
{
    if (sel == @selector(playMediaDiscoverer:withMedia:))
        return @"playMediaDiscovererWithMedia";
    if (sel == @selector(playCocoaObject:))
        return @"playCocoaObject";
    if (sel == @selector(remove:))
        return @"remove";
    if (sel == @selector(setLabel:forMedia:))
        return @"setLabelForMedia";
    return [super webScriptNameForSelector:sel];
}

- (void)selectAll:(id)sender
{
    NSArrayController *controller = [[VLCDocumentController sharedDocumentController] currentArrayController];
    [controller setSelectedObjects:[controller arrangedObjects]];
}
@end
