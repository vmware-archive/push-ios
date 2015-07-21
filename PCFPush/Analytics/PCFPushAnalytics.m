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

@implementation PCFPushAnalytics

+ (void)logReceivedRemoteNotification:(NSString*)receiptId
{
    NSDictionary *parameters = @{ @"receiptId":receiptId, @"deviceUuid":[PCFPushPersistentStorage serverDeviceID]};
    [PCFPushAnalytics logEvent:PCF_PUSH_EVENT_TYPE_PUSH_NOTIFICATION_RECEIVED withParameters:parameters];
}

+ (void)logEvent:(NSString *)eventType
{
    [PCFPushAnalytics logEvent:eventType withParameters:nil];
}

+ (void)logEvent:(NSString *)eventType withParameters:(NSDictionary *)parameters
{
    if (!PCFPushPersistentStorage.areAnalyticsEnabled) {
        PCFPushLog(@"Analytics disabled. Event will not be logged.");
        return;
    }

    NSManagedObjectContext *context = PCFPushAnalyticsStorage.shared.managedObjectContext;
    [context performBlock:^{
        [PCFPushAnalytics insertIntoContext:context eventWithType:eventType parameters:parameters];
        NSError *error;
        if (![context save:&error]) {
            PCFPushCriticalLog(@"Managed Object Context failed to save: %@ %@", error, error.userInfo);
        }
    }];
}

+ (void)insertIntoContext:(NSManagedObjectContext *)context
            eventWithType:(NSString *)eventType
               parameters:(NSDictionary *)parameters
{
    NSEntityDescription *description = [NSEntityDescription entityForName:NSStringFromClass(PCFPushAnalyticsEvent.class) inManagedObjectContext:context];
    PCFPushAnalyticsEvent *event = [[PCFPushAnalyticsEvent alloc] initWithEntity:description insertIntoManagedObjectContext:context];
    event.eventType = eventType;
    event.eventTime = [NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970]];
    event.receiptId = parameters[@"receiptId"];
    event.deviceUuid = parameters[@"deviceUuid"];
    event.geofenceId = parameters[@"geofenceId"];
    event.locationId = parameters[@"locationId"];
}

@end