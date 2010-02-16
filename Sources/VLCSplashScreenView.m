//
//  VLCSplashScreenView.m
//  Lunettes
//
//  Created by Pierre d'Herbemont on 2/1/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "VLCSplashScreenView.h"
#import "VLCDocumentController.h"

@implementation VLCSplashScreenView
- (NSString *)pageName
{
    return @"splash-screen";
}

- (void)awakeFromNib
{
    [self setup];
}

- (NSArrayController *)mediaDiscovererArrayController
{
    return [[[self window] windowController] mediaDiscovererArrayController];
}

- (NSArrayController *)currentlyWatchingItemsArrayController
{
    return [[[self window] windowController] currentlyWatchingItemsArrayController];
}

- (NSArrayController *)unseenItemsArrayController
{
    return [[[self window] windowController] unseenItemsArrayController];
}

- (NSArrayController *)seenItemsArrayController
{
    return [[[self window] windowController] seenItemsArrayController];
}


- (void)playCocoaObject:(WebScriptObject *)object
{
    id representedObject = [object valueForKey:@"backendObject"];
    NSString *stringURL = [representedObject valueForKey:@"url"];
    NSURL *url = [NSURL URLWithString:stringURL];
    NSAssert(url, @"Invalid string in DB!");
    double position = [[representedObject valueForKey:@"lastPosition"] doubleValue];
    [[VLCDocumentController sharedDocumentController] makeDocumentWithURL:url andStartingPosition:position];
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)sel
{
    if (sel == @selector(playCocoaObject:))
        return NO;
    return [super isSelectorExcludedFromWebScript:sel];
}

+ (NSString *)webScriptNameForSelector:(SEL)sel
{
    if (sel == @selector(playCocoaObject:))
        return @"playCocoaObject";
    return [super webScriptNameForSelector:sel];
}
@end
