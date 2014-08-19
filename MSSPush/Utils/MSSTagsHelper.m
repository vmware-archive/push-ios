//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "MSSTagsHelper.h"

@implementation MSSTagsHelper

+ (instancetype) tagsHelperWithSavedTags:(NSArray*)savedTags newTags:(NSArray*)newTags
{
    return [[MSSTagsHelper alloc] initWithSavedTags:savedTags newTags:newTags];
}

- (instancetype) initWithSavedTags:(NSArray*)savedTags newTags:(NSArray*)newTags
{
    self = [super init];
    if (self) {
        self.subscribeTags = [NSMutableArray array];
        self.unsubscribeTags = [NSMutableArray array];
        if (savedTags && newTags) {
            [self generateListsWithSavedTags:savedTags newTags:newTags];
        }
    }
    return self;
}

- (void) generateListsWithSavedTags:(NSArray*)savedTags newTags:(NSArray*)newTags
{
    if (savedTags.count <= 0) {
        [(NSMutableArray*) self.subscribeTags addObjectsFromArray:newTags];
    } else if (newTags.count <= 0) {
        [(NSMutableArray*) self.unsubscribeTags addObjectsFromArray:savedTags];
    } else {
        NSMutableSet *newTagsSet = [NSMutableSet setWithArray:newTags];
        NSMutableSet *savedTagsSet = [NSMutableSet setWithArray:savedTags];
        [newTagsSet minusSet:savedTagsSet]; // gives us the tags we need to subscribe to
        [savedTagsSet minusSet:[NSSet setWithArray:newTags]]; // gives us the tags we need to unsubscribe from
        [(NSMutableArray*) self.subscribeTags addObjectsFromArray:newTagsSet.allObjects];
        [(NSMutableArray*) self.unsubscribeTags addObjectsFromArray:savedTagsSet.allObjects];
        
        // Sort both of the lists so that unit tests can pass
        static dispatch_once_t onceToken;
        static NSComparisonResult (^comparator)(id obj1, id obj2);
        dispatch_once(&onceToken, ^{
            comparator = ^NSComparisonResult(id obj1, id obj2) {
                NSString *tag1 = (NSString*) obj1;
                NSString *tag2 = (NSString*) obj2;
                return [tag1 compare:tag2];
            };
        });
        
        [(NSMutableArray*) self.subscribeTags sortUsingComparator:comparator];
        [(NSMutableArray*) self.unsubscribeTags sortUsingComparator:comparator];
    }
}

@end
