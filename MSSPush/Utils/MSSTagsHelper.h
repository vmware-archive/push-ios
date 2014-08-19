//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MSSTagsHelper : NSObject

@property (nonatomic) NSArray *subscribeTags;
@property (nonatomic) NSArray *unsubscribeTags;

+ (instancetype) tagsHelperWithSavedTags:(NSArray*)savedTags newTags:(NSArray*)newTags;

@end
