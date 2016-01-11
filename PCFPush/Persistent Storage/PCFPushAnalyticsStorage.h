//
// Created by DX173-XL on 15-07-20.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PCFPushAnalyticsEvent.h"

@interface PCFPushAnalyticsStorage : NSObject

+ (instancetype)shared;

+ (void)setSharedManager:(PCFPushAnalyticsStorage *)manager;

+ (NSManagedObjectModel *)newestManagedObjectModel;
+ (NSManagedObjectModel *)managedObjectModelV1;
+ (NSManagedObjectModel *)managedObjectModelV2;
+ (NSManagedObjectModel *)managedObjectModelV3;
+ (NSArray<NSManagedObjectModel*>*)allManagedObjectModels;
+ (NSUInteger)numberOfMigrationsExecuted;

- (void)resetDatabase:(BOOL)keepDatabaseFile;

- (NSManagedObjectContext *)managedObjectContext;

- (NSArray<PCFPushAnalyticsEvent*> *)events;

- (NSArray<PCFPushAnalyticsEvent*> *)eventsWithStatus:(PCFPushEventStatus)status;

- (NSArray<PCFPushAnalyticsEvent*> *) unpostedEvents;

- (NSArray<PCFPushAnalyticsEvent*> *)managedObjectsWithEntityName:(NSString *)entityName;

- (NSArray<PCFPushAnalyticsEvent*> *)managedObjectsWithEntityName:(NSString *)entityName predicate:(NSPredicate *)predicate fetchLimit:(NSUInteger)fetchLimit;

- (void)deleteManagedObjects:(NSArray *)managedObjects;

- (void)setEventsStatus:(NSArray<PCFPushAnalyticsEvent*> *)events status:(PCFPushEventStatus)status;

- (NSUInteger) numberOfEvents;

- (void) cleanupDatabase;

+ (NSUInteger) maximumNumberOfEvents;

@end