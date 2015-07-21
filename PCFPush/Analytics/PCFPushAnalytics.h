//
// Created by DX173-XL on 15-07-20.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import <Foundation/Foundation.h>

#define PCF_PUSH_EVENT_TYPE_PUSH_NOTIFICATION_RECEIVED      @"PCF_PUSH_EVENT_TYPE_PUSH_NOTIFICATION_RECEIVED"
#define PCF_PUSH_EVENT_TYPE_PUSH_NOTIFICATION_OPENED        @"PCF_PUSH_EVENT_TYPE_PUSH_NOTIFICATION_OPENED"
#define PCF_PUSH_EVENT_TYPE_PUSH_GEOFENCE_LOCATION_TRIGGER  @"PCF_PUSH_EVENT_TYPE_PUSH_GEOFENCE_LOCATION_TRIGGER"

@interface PCFPushAnalytics : NSObject

+ (void)logReceivedRemoteNotification:(NSString*)receiptId;
+ (void)logEvent:(NSString *)eventName;
+ (void)logEvent:(NSString *)eventName withParameters:(NSDictionary *)parameters;

@end