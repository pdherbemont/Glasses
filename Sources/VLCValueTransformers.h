//
//  VLCValueTransformers.h
//  Lunettes
//
//  Created by Pierre d'Herbemont on 12/6/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface VLCFloat10000FoldTransformer : NSObject
@end

@interface VLCRateToSliderTransformer : NSObject
@end

@interface VLCDictionaryValuesToArray : NSObject
@end

@interface VLCTimeAsNumberToPrettyTime : NSObject
@end

@interface VLCStringToURL : NSObject
@end

@interface VLCWebScriptObjectToIndexSet : NSObject
@end
