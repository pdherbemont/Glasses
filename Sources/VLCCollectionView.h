//
//  VLCCollectionView.h
//  Lunettes
//
//  Created by Pierre d'Herbemont on 12/5/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface VLCCollectionView : NSCollectionView {
#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_5
    id _delegate;
#endif
    BOOL _isSelectionChanging;
}
#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_5
- (void)setDelegate:(id)obj;
- (id)delegate;
#endif
@end

@interface NSObject (ExtendedDelegate)
- (void)collectionView:(NSCollectionView *)collectionView doubleClickedOnItemAtIndex:(NSUInteger)idx;
- (void)collectionView:(NSCollectionView *)collectionView willChangeSelectionIndexes:(NSIndexSet *)set;
@end

