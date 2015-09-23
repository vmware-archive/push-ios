//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSSet<NSString*> *pcfPushLowercaseTags(NSSet<NSString*> *tags);

@interface PCFTagsHelper : NSObject

@property (nonatomic) NSSet<NSString*> *subscribeTags;
@property (nonatomic) NSSet<NSString*> *unsubscribeTags;

+ (instancetype) tagsHelperWithSavedTags:(NSSet<NSString*> *)savedTags newTags:(NSSet<NSString*> *)newTags;

@end
