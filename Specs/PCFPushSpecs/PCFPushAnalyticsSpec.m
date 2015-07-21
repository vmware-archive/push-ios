//
//  PCFPushAnalyticsSpec.m
//  PCFPushPushSpec
//

#import "Kiwi.h"
#import <CoreData/CoreData.h>
#import "PCFPushAnalytics.h"
#import "PCFPushAnalyticsEvent.h"
#import "PCFPushAnalyticsStorage.h"
#import "PCFPushPersistentStorage.h"

SPEC_BEGIN(PCFPushAnalyticsSpec)

    beforeEach(^{
        [PCFPushPersistentStorage reset];
    });

    describe(@"Logging an event", ^{

        __block PCFPushAnalyticsStorage *storage;
        __block NSString *entityName;

        beforeEach(^{
            entityName = NSStringFromClass(PCFPushAnalyticsEvent.class);

            storage = PCFPushAnalyticsStorage.shared;
            [storage.managedObjectContext stub:@selector(performBlock:) withBlock:^id(NSArray *params) {
                void (^block)() = params[0];
                // Execute asynchronous blocks immediately for tests
                [storage.managedObjectContext performBlockAndWait:block];
                return nil;
            }];

            // Clear database before each test
            [storage flushDatabase];
            [PCFPushAnalyticsStorage setSharedManager:nil];
        });

        it(@"should let you log an event successfully", ^{

            [PCFPushAnalytics logEvent:@"TEST_EVENT"];

            NSArray *events = [PCFPushAnalyticsStorage.shared managedObjectsWithEntityName:entityName];
            [[theValue(events.count) should] equal:theValue(1)];
            PCFPushAnalyticsEvent *event = events.lastObject;
            [[event should] beKindOfClass:NSClassFromString(entityName)];
            [[event.eventType should] equal:@"TEST_EVENT"];
        });

        it(@"should let you log several event successfully", ^{

            [PCFPushAnalytics logEvent:@"TEST_EVENT1"];
            [PCFPushAnalytics logEvent:@"TEST_EVENT2"];
            [PCFPushAnalytics logEvent:@"TEST_EVENT3"];

            NSArray *events = [PCFPushAnalyticsStorage.shared managedObjectsWithEntityName:entityName];
            [[theValue(events.count) should] equal:theValue(3)];
        });

        it(@"should let you set the event fields", ^{

            [PCFPushAnalytics logEvent:@"AMAZING_EVENT" withParameters:@{ @"receiptId":@"TEST_RECEIPT_ID", @"deviceUuid":@"TEST_DEVICE_UUID", @"geofenceId":@"TEST_GEOFENCE_ID", @"locationId":@"TEST_LOCATION_ID" }];

            NSArray *events = [PCFPushAnalyticsStorage.shared managedObjectsWithEntityName:entityName];
            [[theValue(events.count) should] equal:theValue(1)];
            PCFPushAnalyticsEvent *event = events.lastObject;
            [[event should] beKindOfClass:NSClassFromString(entityName)];
            [[event.eventType should] equal:@"AMAZING_EVENT"];
            [[event.receiptId should] equal:@"TEST_RECEIPT_ID"];
            [[event.deviceUuid should] equal:@"TEST_DEVICE_UUID"];
            [[event.geofenceId should] equal:@"TEST_GEOFENCE_ID"];
            [[event.locationId should] equal:@"TEST_LOCATION_ID"];
            [[event.eventTime shouldNot] beNil];
        });

        it(@"should let you log when remote notifications are received", ^{

            [PCFPushPersistentStorage setServerDeviceID:@"TEST_DEVICE_UUID"];

            [PCFPushAnalytics logReceivedRemoteNotification:@"TEST_RECEIPT_ID"];

            NSArray *events = [PCFPushAnalyticsStorage.shared managedObjectsWithEntityName:entityName];
            [[theValue(events.count) should] equal:theValue(1)];
            PCFPushAnalyticsEvent *event = events.lastObject;
            [[event should] beKindOfClass:NSClassFromString(entityName)];
            [[event.eventType should] equal:PCF_PUSH_EVENT_TYPE_PUSH_NOTIFICATION_RECEIVED];
            [[event.receiptId should] equal:@"TEST_RECEIPT_ID"];
            [[event.deviceUuid should] equal:@"TEST_DEVICE_UUID"];
            [[event.geofenceId should] beNil];
            [[event.locationId should] beNil];
            [[event.eventTime shouldNot] beNil];
        });
    });

SPEC_END