//
// Created by DX173-XL on 15-07-20.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PCFPushAnalyticsEvent.h"

@interface PCFPushAnalyticsStorage : NSObject

+ (instancetype)shared;

+ (void)setSharedManager:(PCFPushAnalyticsStorage *)manager;

- (void)flushDatabase;

- (NSManagedObjectContext *)managedObjectContext;

- (NSArray *)events;

- (NSArray *)eventsWithStatus:(PCFPushEventStatus)status;

- (NSArray*) unpostedEvents;

- (NSArray *)managedObjectsWithEntityName:(NSString *)entityName;

- (NSArray *) managedObjectsWithEntityName:(NSString*)entityName predicate:(NSPredicate*)predicate;

- (void)deleteManagedObjects:(NSArray *)managedObjects;

- (void)setEventsStatus:(NSArray *)events status:(PCFPushEventStatus)status;

@end