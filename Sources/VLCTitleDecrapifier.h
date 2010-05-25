//
//  VLCTitleDecrapifier.h
//  Lunettes
//
//  Created by Pierre d'Herbemont on 5/6/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface VLCTitleDecrapifier : NSObject
{
}
+ (NSString *)decrapify:(NSString *)string;
+ (BOOL)isTVShowEpisodeTitle:(NSString *)string;

+ (NSDictionary *)tvShowEpisodeInfoFromString:(NSString *)string;
@end
