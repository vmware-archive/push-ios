//
// Created by DX173-XL on 15-07-20.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "PCFMapping.h"
#import "PCFSortDescriptors.h"

@interface PCFPushAnalyticsEvent : NSManagedObject <PCFMapping, PCFSortDescriptors>

@property (nonatomic, readwrite) NSString *eventType;
@property (nonatomic, readwrite) NSString *eventTime;
@property (nonatomic, readwrite) NSString *receiptId;
@property (nonatomic, readwrite) NSString *deviceUuid;
@property (nonatomic, readwrite) NSString *geofenceId;
@property (nonatomic, readwrite) NSString *locationId;

@end