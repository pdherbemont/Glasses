//
//  VLCArrayController.m
//  Lunettes
//
//  Created by Pierre d'Herbemont on 12/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "VLCArrayController.h"


@implementation VLCArrayController
- (id)init
{
    self = [super init];
    if (!self)
        return nil;
    _searchString = [@"" retain];
    return self;
}

- (void)dealloc
{
    [_searchString release];
    [super dealloc];
}

- (NSString *)searchString
{
    return _searchString;
}

- (void)setSearchString:(NSString *)string
{
    // This method is a hack for now.
    // We should only pass the predicate string, and make
    // no assumption of the content.
    NSPredicate *predicate;
    if (!string || [string isEqualToString:@""])
        predicate = [NSPredicate predicateWithValue:YES];
    else
        predicate = [NSPredicate predicateWithFormat:@"metaDictionary.title CONTAINS[cd] %@", string];
    [self setFilterPredicate:predicate];
    [_searchString release];
    _searchString = [string retain];
}
@end
