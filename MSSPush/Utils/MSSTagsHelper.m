//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "MSSTagsHelper.h"

@implementation MSSTagsHelper

+ (instancetype) tagsHelperWithSavedTags:(NSSet*)savedTags newTags:(NSSet*)newTags
{
    return [[MSSTagsHelper alloc] initWithSavedTags:savedTags newTags:newTags];
}

- (instancetype) initWithSavedTags:(NSSet*)savedTags newTags:(NSSet*)newTags
{
    self = [super init];
    if (self) {
        self.subscribeTags = [NSSet set];
        self.unsubscribeTags = [NSSet set];
        if (savedTags && newTags) {
            [self generateListsWithSavedTags:savedTags newTags:newTags];
        }
    }
    return self;
}

- (void) generateListsWithSavedTags:(NSSet*)savedTags newTags:(NSSet*)newTags
{
    if (savedTags.count <= 0) {
        self.subscribeTags = [NSSet setWithSet:newTags];
    } else if (newTags.count <= 0) {
        self.unsubscribeTags = [NSSet setWithSet:savedTags];
    } else {
        self.subscribeTags = [NSMutableSet setWithSet:newTags];
        self.unsubscribeTags = [NSMutableSet setWithSet:savedTags];
        [(NSMutableSet*) self.subscribeTags minusSet:savedTags];
        [(NSMutableSet*) self.unsubscribeTags minusSet:newTags];
    }
}

@end
