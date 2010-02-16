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

- (void)selectionWillChangeToIndexSet:(NSIndexSet *)set
{
    if (_isSelectionChanging)
        return;

    _isSelectionChanging = YES;
    id delegate = [self delegate];
    if ([delegate respondsToSelector:@selector(collectionView:willChangeSelectionIndexes:)])
        [delegate collectionView:self willChangeSelectionIndexes:set];
    _isSelectionChanging = NO;
}

- (NSView *)hitTest:(NSPoint)aPoint
{
    NSView *result = [super hitTest:aPoint];

    // We handle double click in this object's -mouseDown:
    // thus, we need to make sure we'll handle the event (ie - we return self).

    // The only exception is the NSButton class, that want to answer properly
    // to event. For now, this is the only exception. But if we add complex
    // UI element that are not transparent to event, we'll need to add
    // them here.
    if ([result isKindOfClass:[NSButton class]])
        return result;
    return self;
}

- (void)mouseDown:(NSEvent *)theEvent
{
    if ([theEvent clickCount] == 2)
        [self sendActionOnSelectedItem];

    [super mouseDown:theEvent];
}

- (void)setSelectionIndexes:(NSIndexSet *)indexes
{
    [self selectionWillChangeToIndexSet:indexes];
    [super setSelectionIndexes:indexes];
}

@end
