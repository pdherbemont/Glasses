//
//  VLCCollectionView.m
//  Lunettes
//
//  Created by Pierre d'Herbemont on 12/5/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "VLCCollectionView.h"

@implementation VLCCollectionView

#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_5
- (void)setDelegate:(id)obj
{
    if (_delegate)
        [_delegate release];
    _delegate = obj;
    [_delegate retain];
}

- (id)delegate
{
    return _delegate;
}
#endif

- (void)sendActionOnSelectedItem
{
    id delegate = self.delegate;
    if ([delegate respondsToSelector: @selector(collectionView:doubleClickedOnItemAtIndex:)]) {
        NSUInteger selection = [[self selectionIndexes] firstIndex];
        if (selection != NSNotFound)
            [delegate collectionView:self doubleClickedOnItemAtIndex:selection];
    }
}

- (void)keyDown:(NSEvent *)theEvent
{
    if ([[theEvent characters] characterAtIndex:0] == 13)
        [self sendActionOnSelectedItem];
    else
        [super keyDown:theEvent];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    if ([theEvent clickCount] == 2)
        [self sendActionOnSelectedItem];

    [super mouseDown:theEvent];
}

@end
