//
// Created by DX173-XL on 15-07-20.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PCFPushAnalyticsStorage : NSObject

+ (instancetype)shared;

+ (void)setSharedManager:(PCFPushAnalyticsStorage *)manager;

- (void)flushDatabase;

- (NSManagedObjectContext *)managedObjectContext;

- (NSArray *)managedObjectsWithEntityName:(NSString *)entityName;

- (void)deleteManagedObjects:(NSArray *)managedObjects;

@end