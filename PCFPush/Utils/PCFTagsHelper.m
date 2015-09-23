//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "PCFTagsHelper.h"

NSSet<NSString*> *pcfPushLowercaseTags(NSSet<NSString*> *tags)
{
    if (!tags) {
        return nil;
    }

    NSMutableSet<NSString*> *s = [NSMutableSet<NSString*> setWithCapacity:tags.count];
    for (NSString *tag in tags) {
        [s addObject:tag.lowercaseString];
    }

    return s;
}

@implementation PCFTagsHelper

+ (instancetype) tagsHelperWithSavedTags:(NSSet<NSString*> *)savedTags newTags:(NSSet<NSString*> *)newTags
{
    return [[PCFTagsHelper alloc] initWithSavedTags:savedTags newTags:newTags];
}

- (instancetype) initWithSavedTags:(NSSet<NSString*> *)savedTags newTags:(NSSet<NSString*> *)newTags
{
    self = [super init];
    if (self) {
        [self generateListsWithSavedTags:savedTags newTags:newTags];
    }
    return self;
}

- (void) generateListsWithSavedTags:(NSSet<NSString*> *)savedTags newTags:(NSSet<NSString*> *)newTags
{
    if (!savedTags && !newTags) {
        self.unsubscribeTags = [NSSet<NSString*> set];
        self.subscribeTags = [NSSet<NSString*> set];
        
    } else if (!savedTags || savedTags.count <= 0) {
        self.unsubscribeTags = [NSSet<NSString*> set];
        self.subscribeTags = [NSSet<NSString*> setWithSet:newTags];

    } else if (!newTags || newTags.count <= 0) {
        self.subscribeTags = [NSSet<NSString*> set];
        self.unsubscribeTags = [NSSet<NSString*> setWithSet:savedTags];
    
    } else {
        self.subscribeTags = [NSMutableSet<NSString*> setWithSet:newTags];
        self.unsubscribeTags = [NSMutableSet<NSString*> setWithSet:savedTags];
        [(NSMutableSet<NSString*> *) self.subscribeTags minusSet:savedTags];
        [(NSMutableSet<NSString*> *) self.unsubscribeTags minusSet:newTags];
    }
}

@end
