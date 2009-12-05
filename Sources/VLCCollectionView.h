//
//  VLCCollectionView.h
//  Lunettes
//
//  Created by Pierre d'Herbemont on 12/5/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface VLCCollectionView : NSCollectionView {
}
@end

@interface NSObject (ExtendedDelegate)
- (void)collectionView:(NSCollectionView *)collectionView doubleClickedOnItem:(NSCollectionViewItem *)item;
@end

