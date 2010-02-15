//
//  VLCDVDDiscoverer.h
//  Lunettes
//
//  Created by Moi on 12/02/10.
//  Copyright 2010 école Centrale de Lyon. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <VLCKit/VLCKit.h>

@interface VLCDVDDiscoverer : VLCMediaDiscoverer {

}

- (void)updateDVDList:(NSNotification *)notification;

@end
