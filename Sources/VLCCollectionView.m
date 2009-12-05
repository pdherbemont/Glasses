//
//  VLCCollectionView.m
//  Lunettes
//
//  Created by Pierre d'Herbemont on 12/5/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "VLCCollectionView.h"

@implementation VLCCollectionView

- (void)sendActionOnSelectedItem
{
    id delegate = self.delegate;
    if ([delegate respondsToSelector: @selector(collectionView:doubleClickedOnItem:)]) {
        NSInteger selection = [[self selectionIndexes] firstIndex];
        if (selection != NSNotFound)
            [delegate collectionView:self doubleClickedOnItem:[self itemAtIndex:selection]];
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
