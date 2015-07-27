//
// Created by DX173-XL on 15-07-20.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import "PCFPushAnalytics.h"
#import <CoreData/CoreData.h>
#import "PCFPushDebug.h"
#import "PCFPushPersistentStorage.h"
#import "PCFPushAnalyticsStorage.h"
#import "PCFPushAnalyticsEvent.h"
#import "PCFPushParameters.h"
#import "PCFPushURLConnection.h"

@implementation PCFPushAnalytics

+ (void)logReceivedRemoteNotification:(NSString *)receiptId parameters:(PCFPushParameters *)parameters
{
    NSDictionary *fields = @{ @"receiptId":receiptId, @"deviceUuid":[PCFPushPersistentStorage serverDeviceID]};
    PCFPushLog(@"Logging received remote notification for receiptId:%@", receiptId);
    [PCFPushAnalytics logEvent:PCF_PUSH_EVENT_TYPE_PUSH_NOTIFICATION_RECEIVED fields:fields parameters:parameters];
}

+ (void)logOpenedRemoteNotification:(NSString *)receiptId parameters:(PCFPushParameters *)parameters
{
    NSDictionary *fields = @{ @"receiptId":receiptId, @"deviceUuid":[PCFPushPersistentStorage serverDeviceID]};
    PCFPushLog(@"Logging opened remote notification for receiptId:%@", receiptId);
    [PCFPushAnalytics logEvent:PCF_PUSH_EVENT_TYPE_PUSH_NOTIFICATION_OPENED fields:fields parameters:parameters];
}

+ (void)logTriggeredGeofenceId:(int64_t)geofenceId locationId:(int64_t)locationId parameters:(PCFPushParameters *)parameters
{
    NSDictionary *fields = @{ @"geofenceId":[NSString stringWithFormat:@"%lld", geofenceId], @"locationId":[NSString stringWithFormat:@"%lld", locationId], @"deviceUuid":[PCFPushPersistentStorage serverDeviceID]};
    PCFPushLog(@"Logging triggered geofenceId %lld and locationId %lld", geofenceId, locationId);
    [PCFPushAnalytics logEvent:PCF_PUSH_EVENT_TYPE_PUSH_GEOFENCE_LOCATION_TRIGGER fields:fields parameters:parameters];
}

+ (void)logEvent:(NSString *)eventType parameters:(PCFPushParameters *)parameters
{
    [PCFPushAnalytics logEvent:eventType fields:nil parameters:parameters];
}

+ (void)logEvent:(NSString *)eventType
          fields:(NSDictionary *)fields
      parameters:(PCFPushParameters *)parameters
{
    if (!parameters.areAnalyticsEnabled) {
        PCFPushLog(@"Analytics disabled. Event will not be logged.");
        return;
    }

    NSManagedObjectContext *context = PCFPushAnalyticsStorage.shared.managedObjectContext;
    [context performBlock:^{
        [PCFPushAnalytics insertIntoContext:context eventWithType:eventType fields:fields];
        NSError *error;
        if (![context save:&error]) {
            PCFPushCriticalLog(@"Managed Object Context failed to save: %@ %@", error, error.userInfo);
        }
    }];
}

+ (void)insertIntoContext:(NSManagedObjectContext *)context
            eventWithType:(NSString *)eventType
                   fields:(NSDictionary *)fields
{
    NSEntityDescription *description = [NSEntityDescription entityForName:NSStringFromClass(PCFPushAnalyticsEvent.class) inManagedObjectContext:context];
    PCFPushAnalyticsEvent *event = [[PCFPushAnalyticsEvent alloc] initWithEntity:description insertIntoManagedObjectContext:context];
    event.eventType = eventType;
    event.eventTime = [NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970]];
    event.receiptId = fields[@"receiptId"];
    event.deviceUuid = fields[@"deviceUuid"];
    event.geofenceId = fields[@"geofenceId"];
    event.locationId = fields[@"locationId"];
    event.status = @(PCFPushEventStatusNotPosted);
}

@end