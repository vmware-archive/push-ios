//
// Created by DX173-XL on 15-07-20.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import "PCFPushAnalytics.h"
#import <CoreData/CoreData.h>
#import "PCFPushDebug.h"
#import "PCFPushPersistentStorage.h"
#import "PCFPushAnalyticsStorage.h"
#import "PCFPushParameters.h"
#import "PCFPushURLConnection.h"
#import "PCFPushClient.h"

static UIBackgroundTaskIdentifier backgroundTaskIdentifier;
static BOOL areAnalyticsSetUp = NO;

@implementation PCFPushAnalytics

// Used in unit tests
+ (void)resetAnalytics
{
    areAnalyticsSetUp = NO;
}

+ (void)logReceivedRemoteNotification:(NSString *)receiptId parameters:(PCFPushParameters *)parameters
{
    if (!parameters.areAnalyticsEnabled) {
        return;
    }

    NSDictionary *fields = @{ @"receiptId":receiptId, @"deviceUuid":[PCFPushPersistentStorage serverDeviceID]};
    PCFPushLog(@"Logging received remote notification for receiptId:%@", receiptId);
    [PCFPushAnalytics logEvent:PCF_PUSH_EVENT_TYPE_PUSH_NOTIFICATION_RECEIVED fields:fields parameters:parameters];
}

+ (void)logOpenedRemoteNotification:(NSString *)receiptId parameters:(PCFPushParameters *)parameters
{
    if (!parameters.areAnalyticsEnabled) {
        return;
    }

    NSDictionary *fields = @{ @"receiptId":receiptId, @"deviceUuid":[PCFPushPersistentStorage serverDeviceID]};
    PCFPushLog(@"Logging opened remote notification for receiptId:%@", receiptId);
    [PCFPushAnalytics logEvent:PCF_PUSH_EVENT_TYPE_PUSH_NOTIFICATION_OPENED fields:fields parameters:parameters];
}

+ (void)logTriggeredGeofenceId:(int64_t)geofenceId locationId:(int64_t)locationId parameters:(PCFPushParameters *)parameters
{
    if (!parameters.areAnalyticsEnabled) {
        return;
    }

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
    if (!parameters.areAnalyticsEnabledAndAvailable) {
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
    
    int64_t date = (int64_t) ([[NSDate date] timeIntervalSince1970] * 1000.0);
    event.eventTime = [NSString stringWithFormat:@"%lld", date];
    
    event.receiptId = fields[@"receiptId"];
    event.deviceUuid = fields[@"deviceUuid"];
    event.geofenceId = fields[@"geofenceId"];
    event.locationId = fields[@"locationId"];
    event.status = @(PCFPushEventStatusNotPosted);
}

+ (BOOL)isAnalyticsPollingTime:(PCFPushParameters *)parameters
{
    if (!parameters.areAnalyticsEnabled) {
        return NO;
    }

    NSDate *lastPollingTime = PCFPushPersistentStorage.serverVersionTimePolled;
    if (!lastPollingTime) {
        return YES;
    }

    NSTimeInterval pollingInterval;
    if (pcfPushIsAPNSSandbox()) {
        pollingInterval = 60; // 1 minute in debug (sandbox) builds
    } else {
        pollingInterval = 24 * 60 * 60; // 24 hours in release builds
    };

    return NSDate.date.timeIntervalSince1970 >= lastPollingTime.timeIntervalSince1970 + pollingInterval;
}

+ (void)setupAnalytics:(PCFPushParameters *)parameters
{
    if (!parameters.areAnalyticsEnabled) {
        return;
    }

    if ([PCFPushAnalytics isAnalyticsPollingTime:parameters]) {
        [PCFPushAnalytics checkAnalytics:parameters];

    } else if (!areAnalyticsSetUp && parameters.areAnalyticsEnabledAndAvailable) {
        [PCFPushAnalytics prepareEventsDatabase];
    }
}

+ (void)checkAnalytics:(PCFPushParameters *)parameters
{
    if (!parameters.areAnalyticsEnabled) {
        return;
    }

    [PCFPushURLConnection versionRequestWithParameters:parameters success:^(NSString *version) {

        PCFPushLog(@"PCF Push server is version '%@'. Push analytics are enabled.", version);

        [PCFPushPersistentStorage setServerVersion:version];
        [PCFPushPersistentStorage setServerVersionTimePolled:NSDate.date];

        if (!areAnalyticsSetUp && parameters.areAnalyticsEnabledAndAvailable) {
            [PCFPushAnalytics prepareEventsDatabase];
        }

    } oldVersion:^{

        PCFPushLog(@"PCF Push server version is old. Push analytics are disabled.");

        [PCFPushPersistentStorage setServerVersion:nil];
        [PCFPushPersistentStorage setServerVersionTimePolled:NSDate.date];

    } failure:^(NSError *error) {

        PCFPushLog(@"Not able to successfully check the PCF Push server version");
    }];
}

+ (void)prepareEventsDatabase
{
    areAnalyticsSetUp = YES;

    [PCFPushAnalyticsStorage.shared.managedObjectContext performBlock:^{

        NSArray *postingEvents = [PCFPushAnalyticsStorage.shared eventsWithStatus:PCFPushEventStatusPosting];
        if (postingEvents && postingEvents.count > 0) {
            PCFPushLog(@"Found %d analytics events with status 'posting'. Setting their status to 'not posted'.", postingEvents.count);
            [PCFPushAnalyticsStorage.shared setEventsStatus:postingEvents status:PCFPushEventStatusNotPosted];
        }

        NSArray *postingErrorEvents = [PCFPushAnalyticsStorage.shared eventsWithStatus:PCFPushEventStatusPostingError];
        if (postingErrorEvents && postingErrorEvents.count > 0) {
            PCFPushLog(@"Found %d analytics events with status 'posting error'. Setting their status to 'not posted'.", postingErrorEvents.count);
            [PCFPushAnalyticsStorage.shared setEventsStatus:postingErrorEvents status:PCFPushEventStatusNotPosted];
        }

        NSArray *unpostedEvents = PCFPushAnalyticsStorage.shared.unpostedEvents;
        if (unpostedEvents && unpostedEvents.count > 0) {
            PCFPushLog(@"There are %d unposted events. They will be sent when the process goes into the background.", unpostedEvents.count);

            // Ensure that we register for the background notification so that we can send analytics events later
            [[NSNotificationCenter defaultCenter] addObserver:PCFPushClient.shared selector:@selector(didEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        } else {
            PCFPushLog(@"There are no unposted analytics events at this time.");
        }
    }];
}

+ (void)sendEventsWithParameters:(PCFPushParameters *)parameters
{
    if (!parameters.areAnalyticsEnabledAndAvailable) {
        return;
    }

    [PCFPushAnalyticsStorage.shared.managedObjectContext performBlockAndWait:^{

        backgroundTaskIdentifier = [UIApplication.sharedApplication beginBackgroundTaskWithName:@"io.pivotal.push.android.uploadAnalyticsEvents" expirationHandler:^{

              PCFPushCriticalLog(@"Process timeout error posting analytics events to server.  Will attempt to send them at the end of the next session...");
              [UIApplication.sharedApplication endBackgroundTask:backgroundTaskIdentifier];
          }];

        NSArray *events = PCFPushAnalyticsStorage.shared.unpostedEvents;

        if (events && events.count > 0) {
            [PCFPushAnalyticsStorage.shared setEventsStatus:events status:PCFPushEventStatusPosting];

            PCFPushLog(@"Posting %d analytics events to the server...", events.count);

            [PCFPushURLConnection analyticsRequestWithEvents:events parameters:parameters success:^(NSURLResponse *response, NSData *data) {

                PCFPushLog(@"Posted %d analytics events to the server successfully.", events.count);
                [PCFPushAnalyticsStorage.shared deleteManagedObjects:events];

                [UIApplication.sharedApplication endBackgroundTask:backgroundTaskIdentifier];

            } failure:^(NSError *error) {

                PCFPushCriticalLog(@"Error posting %d analytics events to server: %@", events.count, error);
                [PCFPushAnalyticsStorage.shared setEventsStatus:events status:PCFPushEventStatusPostingError];

                [UIApplication.sharedApplication endBackgroundTask:backgroundTaskIdentifier];
            }];
        }
    }];
}
@end