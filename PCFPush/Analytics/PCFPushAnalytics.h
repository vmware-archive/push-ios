//
// Created by DX173-XL on 15-07-20.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PCFPushParameters;

#define PCF_PUSH_EVENT_TYPE_PUSH_NOTIFICATION_RECEIVED      @"pcf_push_event_type_push_notification_received"
#define PCF_PUSH_EVENT_TYPE_PUSH_NOTIFICATION_OPENED        @"pcf_push_event_type_push_notification_opened"
#define PCF_PUSH_EVENT_TYPE_PUSH_GEOFENCE_LOCATION_TRIGGER  @"pcf_push_event_type_geofence_location_triggered"
#define PCF_PUSH_EVENT_TYPE_PUSH_HEARTBEAT                  @"pcf_push_event_type_heartbeat"

@interface PCFPushAnalytics : NSObject

// Used in unit tests
+ (void)resetAnalytics;

+ (void)logReceivedRemoteNotification:(NSString *)receiptId parameters:(PCFPushParameters *)parameters;

+ (void)logOpenedRemoteNotification:(NSString *)receiptId parameters:(PCFPushParameters *)parameters;

+ (void)logTriggeredGeofenceId:(int64_t)geofenceId locationId:(int64_t)locationId parameters:(PCFPushParameters *)parameters;

+ (void)logReceivedHeartbeat:(NSString *)receiptId parameters:(PCFPushParameters *)parameters;

+ (void)logEvent:(NSString *)eventName parameters:(PCFPushParameters *)parameters;

+ (void)logEvent:(NSString *)eventName fields:(NSDictionary *)dictionary parameters:(PCFPushParameters *)parameters;

+ (BOOL)isAnalyticsPollingTime:(PCFPushParameters *)parameters;

+ (void)checkAnalytics:(PCFPushParameters *)parameters;

+ (void)setupAnalytics:(PCFPushParameters *)parameters;

+ (void)prepareEventsDatabase;

+ (void)sendEventsWithParameters:(PCFPushParameters *)parameters;

@end