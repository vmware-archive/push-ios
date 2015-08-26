//
// Created by DX173-XL on 15-07-20.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PCFPushParameters;

#define PCF_PUSH_EVENT_TYPE_PUSH_NOTIFICATION_RECEIVED      @"PCF_PUSH_EVENT_TYPE_PUSH_NOTIFICATION_RECEIVED"
#define PCF_PUSH_EVENT_TYPE_PUSH_NOTIFICATION_OPENED        @"PCF_PUSH_EVENT_TYPE_PUSH_NOTIFICATION_OPENED"
#define PCF_PUSH_EVENT_TYPE_PUSH_GEOFENCE_LOCATION_TRIGGER  @"PCF_PUSH_EVENT_TYPE_PUSH_GEOFENCE_LOCATION_TRIGGER"

@interface PCFPushAnalytics : NSObject

// Used in unit tests
+ (void)resetAnalytics;

+ (void)logReceivedRemoteNotification:(NSString *)receiptId parameters:(PCFPushParameters *)parameters;

+ (void)logOpenedRemoteNotification:(NSString *)receiptId parameters:(PCFPushParameters *)parameters;

+ (void)logTriggeredGeofenceId:(int64_t)geofenceId locationId:(int64_t)locationId parameters:(PCFPushParameters *)parameters;

+ (void)logEvent:(NSString *)eventName parameters:(PCFPushParameters *)parameters;

+ (void)logEvent:(NSString *)eventName fields:(NSDictionary *)dictionary parameters:(PCFPushParameters *)parameters;

+ (BOOL)isAnalyticsPollingTime:(PCFPushParameters *)parameters;

+ (void)checkAnalytics:(PCFPushParameters *)parameters;

+ (void)setupAnalytics:(PCFPushParameters *)parameters;

+ (void)prepareEventsDatabase;

+ (void)sendEventsWithParameters:(PCFPushParameters *)parameters;

@end