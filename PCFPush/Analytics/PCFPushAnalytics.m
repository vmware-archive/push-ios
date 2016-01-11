//
// Created by DX173-XL on 15-07-20.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import "PCFPushAnalytics.h"
#import <CoreData/CoreData.h>
#import "PCFPush.h"
#import "PCFPushDebug.h"
#import "PCFPushPersistentStorage.h"
#import "PCFPushAnalyticsStorage.h"
#import "PCFPushParameters.h"
#import "PCFPushURLConnection.h"
#import "PCFPushAnalyticsEvent.h"

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

    NSString *serverDeviceId = [PCFPushPersistentStorage serverDeviceID];
    NSDictionary *fields = @{ @"receiptId":receiptId, @"deviceUuid":serverDeviceId};
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

+ (void)logReceivedHeartbeat:(NSString *)receiptId parameters:(PCFPushParameters *)parameters
{
    if (!parameters.areAnalyticsEnabled) {
        return;
    }

    NSString *serverDeviceId = [PCFPushPersistentStorage serverDeviceID];
    NSDictionary *fields = @{ @"receiptId":receiptId, @"deviceUuid":serverDeviceId};
    PCFPushLog(@"Logging received heartbeat for receiptId:%@", receiptId);
    [PCFPushAnalytics logEvent:PCF_PUSH_EVENT_TYPE_PUSH_HEARTBEAT fields:fields parameters:parameters];
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

        // Ensures that there will be space for the item
        [PCFPushAnalyticsStorage.shared cleanupDatabase];

        [PCFPushAnalytics insertIntoContext:context eventWithType:eventType fields:fields parameters:parameters];
        NSError *error;
        if (![context save:&error]) {
            PCFPushCriticalLog(@"Managed Object Context failed to save: %@ %@", error, error.userInfo);
        }
        PCFPushLog(@"Number of events in database: %d", [[PCFPushAnalyticsStorage shared] numberOfEvents]);
    }];
}

+ (void)insertIntoContext:(NSManagedObjectContext *)context
            eventWithType:(NSString *)eventType
                   fields:(NSDictionary *)fields
               parameters:(PCFPushParameters *)parameters
{
    NSEntityDescription *description = [NSEntityDescription entityForName:NSStringFromClass(PCFPushAnalyticsEvent.class) inManagedObjectContext:context];
    
    PCFPushAnalyticsEvent *event = [[PCFPushAnalyticsEvent alloc] initWithEntity:description insertIntoManagedObjectContext:context];
    
    if (description.propertiesByName[@"sdkVersion"]) {
        // V2+ data model
        event.sdkVersion = PCFPush.sdkVersion;
    }

    if (description.propertiesByName[@"platformType"]) {
        // V3+ data model
        event.platformType = @"ios";
    }

    if (description.propertiesByName[@"platformUuid"]) {
        // V3+ data model
        event.platformUuid = parameters.variantUUID;
    }

    int64_t date = (int64_t) (NSDate.date.timeIntervalSince1970 * 1000.0);
    event.eventTime = [NSString stringWithFormat:@"%lld", date];
    event.eventType = eventType;
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
        [PCFPushAnalytics prepareEventsDatabase:parameters];
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
            [PCFPushAnalytics prepareEventsDatabase:parameters];
        }

    } oldVersion:^{

        PCFPushLog(@"PCF Push server version is old. Push analytics are disabled.");

        [PCFPushPersistentStorage setServerVersion:nil];
        [PCFPushPersistentStorage setServerVersionTimePolled:NSDate.date];

    } failure:^(NSError *error) {

        PCFPushLog(@"Not able to successfully check the PCF Push server version");
    }];
}

+ (void)prepareEventsDatabase:(PCFPushParameters*)parameters
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
            [PCFPushAnalytics sendEventsFromMainQueueWithParameters:parameters];
        } else {
            PCFPushLog(@"There are no unposted analytics events at this time.");
        }
    }];
}

+ (void)sendEventsFromMainQueueWithParameters:(PCFPushParameters *)parameters
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [PCFPushAnalytics sendEventsWithParameters:parameters];
    });
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

        PCFPushAnalyticsEventArray *events = PCFPushAnalyticsStorage.shared.unpostedEvents;

        if (events && events.count > 0) {
            [PCFPushAnalyticsStorage.shared setEventsStatus:events status:PCFPushEventStatusPosting];

            PCFPushLog(@"Posting %d analytics events to the server...", events.count);

            [PCFPushURLConnection analyticsRequestWithEvents:events parameters:parameters success:^(NSURLResponse *response, NSData *data) {

                PCFPushLog(@"Posted %d analytics events to the server successfully.", events.count);
                [PCFPushAnalytics postProcessSentEvents:events];
                [UIApplication.sharedApplication endBackgroundTask:backgroundTaskIdentifier];

            } failure:^(NSError *error) {

                PCFPushCriticalLog(@"Error posting %d analytics events to server: %@", events.count, error);
                [PCFPushAnalyticsStorage.shared setEventsStatus:events status:PCFPushEventStatusPostingError];
                [UIApplication.sharedApplication endBackgroundTask:backgroundTaskIdentifier];
            }];
        }
    }];
}

+ (void) postProcessSentEvents:(PCFPushAnalyticsEventArray*)events
{
    PCFPushAnalyticsEventArray *arrayOfItemsToDelete;
    PCFPushAnalyticsEventArray *arrayOfItemsToSetToPostedStatus;

    [PCFPushAnalytics processEvents:events andFindItemsToDelete:&arrayOfItemsToDelete andItemsToSetToPostedStatus:&arrayOfItemsToSetToPostedStatus];

    [PCFPushAnalyticsStorage.shared setEventsStatus:arrayOfItemsToSetToPostedStatus status:PCFPushEventStatusPosted];
    [PCFPushAnalyticsStorage.shared deleteManagedObjects:arrayOfItemsToDelete];
}

+ (void) processEvents:(PCFPushAnalyticsEventArray *)events
  andFindItemsToDelete:(PCFPushAnalyticsEventArray * __autoreleasing *)arrayOfItemsToDelete
        andItemsToSetToPostedStatus:(PCFPushAnalyticsEventArray * __autoreleasing *)arrayOfItemsToSetToPostedStatus
{
    PCFPushAnalyticsEventMutableArray *toDelete = [PCFPushAnalyticsEventMutableArray array];
    PCFPushAnalyticsEventMutableArray *toPost = [PCFPushAnalyticsEventMutableArray array];

    NSMutableDictionary <NSString*, PCFPushAnalyticsEvent*> *notificationReceivedEvents = [NSMutableDictionary dictionaryWithCapacity:events.count];
    NSMutableDictionary <NSString*, PCFPushAnalyticsEvent*> *notificationOpenedEvents = [NSMutableDictionary dictionaryWithCapacity:events.count];

    [self produceLookupTablesWithEvents:events notificationReceivedEvents:notificationReceivedEvents notificationOpenedEvents:notificationOpenedEvents];

    for (PCFPushAnalyticsEvent *event in events) {

        [self ifRequiredAddEvent:event toDeletionList:toDelete notificationReceivedEvents:notificationReceivedEvents];
        [self ifRequiredAddEvent:event toPostedList:toPost notificationOpenedEvents:notificationOpenedEvents];
    }

    *arrayOfItemsToDelete = toDelete;
    *arrayOfItemsToSetToPostedStatus = toPost;
}

// For reference load all of the 'notification received' and 'notification opened' events into two dictionaries.
+ (void)produceLookupTablesWithEvents:(PCFPushAnalyticsEventArray *)sentEvents notificationReceivedEvents:(NSMutableDictionary *)notificationReceivedEvents notificationOpenedEvents:(NSMutableDictionary *)notificationOpenedEvents
{
    for (PCFPushAnalyticsEvent *event in sentEvents) {
        if ([event.eventType isEqualToString:PCF_PUSH_EVENT_TYPE_PUSH_NOTIFICATION_RECEIVED]) {
            notificationReceivedEvents[event.receiptId] = event;
        } else if ([event.eventType isEqualToString:PCF_PUSH_EVENT_TYPE_PUSH_NOTIFICATION_OPENED]) {
            notificationOpenedEvents[event.receiptId] = event;
        }
    }

    NSArray *storedEvents = PCFPushAnalyticsStorage.shared.events;
    for (PCFPushAnalyticsEvent *event in storedEvents) {
        if ([event.eventType isEqualToString:PCF_PUSH_EVENT_TYPE_PUSH_NOTIFICATION_RECEIVED] && event.status.unsignedIntegerValue == PCFPushEventStatusPosted) {
            notificationReceivedEvents[event.receiptId] = event;
        }
    }
}

+ (void)ifRequiredAddEvent:(PCFPushAnalyticsEvent *)event
            toDeletionList:(PCFPushAnalyticsEventMutableArray *)toDelete
notificationReceivedEvents:(NSMutableDictionary *)notificationReceivedEvents
{
    BOOL willBeDeleted = NO;

    if ([event.eventType isEqualToString:PCF_PUSH_EVENT_TYPE_PUSH_NOTIFICATION_OPENED]) {
        PCFPushAnalyticsEvent *notificationReceivedEvent = notificationReceivedEvents[event.receiptId];
        if (notificationReceivedEvent) {
            [toDelete addObject:notificationReceivedEvent];
            PCFPushLog(@"Event (receiptId:%@ type:%@) status will be deleted.", notificationReceivedEvent.receiptId, notificationReceivedEvent.eventType);
        }

        [toDelete addObject:event];
        willBeDeleted = YES;

    } else if (![event.eventType isEqualToString:PCF_PUSH_EVENT_TYPE_PUSH_NOTIFICATION_RECEIVED]) {
        [toDelete addObject:event];
        willBeDeleted = YES;
    }

    if (willBeDeleted) {
        PCFPushLog(@"Event (receiptId:%@ type:%@) status will be deleted.", event.receiptId, event.eventType);
    }
}

+ (void)ifRequiredAddEvent:(PCFPushAnalyticsEvent *)event
              toPostedList:(PCFPushAnalyticsEventMutableArray *)toPost
  notificationOpenedEvents:(NSMutableDictionary *)notificationOpenedEvents
{
    if ([event.eventType isEqualToString:PCF_PUSH_EVENT_TYPE_PUSH_NOTIFICATION_RECEIVED]) {
        PCFPushAnalyticsEvent *notificationOpenedEvent = notificationOpenedEvents[event.receiptId];
        if (!notificationOpenedEvent) {
            [toPost addObject:event];
            PCFPushLog(@"Event (receiptId:%@ type:%@) status will be set to 'posted'.", event.receiptId, event.eventType);
        }
    }
}

@end
