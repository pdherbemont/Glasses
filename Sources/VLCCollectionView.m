//
//  VLCCollectionView.m
//  Lunettes
//
//  Created by Pierre d'Herbemont on 12/5/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "VLCCollectionView.h"

@implementation VLCCollectionView

- (void)mouseDown:(NSEvent *)theEvent
{
    if ([theEvent clickCount] == 2) {
        id delegate = self.delegate;
        if ([delegate respondsToSelector: @selector(collectionView:doubleClickedOnItem:)]) {
            NSInteger selection = [[self selectionIndexes] firstIndex];
            [delegate collectionView:self doubleClickedOnItem:[self itemAtIndex:selection]];
        }
    }

    [super mouseDown:theEvent];
}

@end
