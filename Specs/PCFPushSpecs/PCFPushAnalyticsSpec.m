//
//  PCFPushAnalyticsSpec.m
//  PCFPushPushSpec
//

#import "Kiwi.h"
#import <CoreData/CoreData.h>
#import "PCFPushAnalytics.h"
#import "PCFPushParameters.h"
#import "PCFPushSpecsHelper.h"
#import "PCFPushAnalyticsEvent.h"
#import "PCFPushAnalyticsStorage.h"
#import "PCFPushPersistentStorage.h"

SPEC_BEGIN(PCFPushAnalyticsSpec)

    beforeEach(^{
        [PCFPushPersistentStorage reset];
    });

    describe(@"Logging an event", ^{

        __block PCFPushSpecsHelper *helper;
        __block NSString *entityName;
        __block PCFPushParameters *parametersWithAnalyticsEnabled;
        __block PCFPushParameters *parametersWithAnalyticsDisabled;

        beforeEach(^{
            entityName = NSStringFromClass(PCFPushAnalyticsEvent.class);
            helper = [[PCFPushSpecsHelper alloc] init];
            [helper setupAnalyticsStorage];
            [helper setupDefaultPLIST];
            parametersWithAnalyticsDisabled = [PCFPushParameters parametersWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"Pivotal-AnalyticsDisabled" ofType:@"plist"]];
            parametersWithAnalyticsEnabled = [PCFPushParameters defaultParameters];
        });

        afterEach(^{
            [helper reset];
            helper = nil;
        });

        describe(@"logging events", ^{

            it(@"should let you log an event successfully", ^{

                [PCFPushAnalytics logEvent:@"TEST_EVENT" parameters:parametersWithAnalyticsEnabled];

                NSArray *events = [PCFPushAnalyticsStorage.shared events];
                [[theValue(events.count) should] equal:theValue(1)];
                PCFPushAnalyticsEvent *event = events.lastObject;
                [[event should] beKindOfClass:NSClassFromString(entityName)];
                [[event.eventType should] equal:@"TEST_EVENT"];
                [[event.status should] equal:@(PCFPushEventStatusNotPosted)];
            });

            it(@"should suppress logging if analytics are disabled", ^{

                [PCFPushAnalytics logEvent:@"TEST_EVENT" parameters:parametersWithAnalyticsDisabled];

                NSArray *events = [PCFPushAnalyticsStorage.shared events];
                [[events should] beEmpty];
            });

            it(@"should let you log several event successfully", ^{

                [PCFPushAnalytics logEvent:@"TEST_EVENT1" parameters:parametersWithAnalyticsEnabled];
                [PCFPushAnalytics logEvent:@"TEST_EVENT2" parameters:parametersWithAnalyticsEnabled];
                [PCFPushAnalytics logEvent:@"TEST_EVENT3" parameters:parametersWithAnalyticsEnabled];

                NSArray *events = [PCFPushAnalyticsStorage.shared events];
                [[theValue(events.count) should] equal:theValue(3)];
            });

            it(@"should let you set the event fields", ^{

                [PCFPushAnalytics logEvent:@"AMAZING_EVENT" fields:@{@"receiptId" : @"TEST_RECEIPT_ID", @"deviceUuid" : @"TEST_DEVICE_UUID", @"geofenceId" : @"TEST_GEOFENCE_ID", @"locationId" : @"TEST_LOCATION_ID"} parameters:parametersWithAnalyticsEnabled];

                NSArray *events = [PCFPushAnalyticsStorage.shared events];
                [[theValue(events.count) should] equal:theValue(1)];
                PCFPushAnalyticsEvent *event = events.lastObject;
                [[event should] beKindOfClass:NSClassFromString(entityName)];
                [[event.eventType should] equal:@"AMAZING_EVENT"];
                [[event.receiptId should] equal:@"TEST_RECEIPT_ID"];
                [[event.deviceUuid should] equal:@"TEST_DEVICE_UUID"];
                [[event.geofenceId should] equal:@"TEST_GEOFENCE_ID"];
                [[event.locationId should] equal:@"TEST_LOCATION_ID"];
                [[event.eventTime shouldNot] beNil];
                [[event.status should] equal:@(PCFPushEventStatusNotPosted)];
            });

            it(@"should let you log when remote notifications are received", ^{

                [PCFPushPersistentStorage setServerDeviceID:@"TEST_DEVICE_UUID"];

                [PCFPushAnalytics logReceivedRemoteNotification:@"TEST_RECEIPT_ID" parameters:parametersWithAnalyticsEnabled];

                NSArray *events = [PCFPushAnalyticsStorage.shared events];
                [[theValue(events.count) should] equal:theValue(1)];
                PCFPushAnalyticsEvent *event = events.lastObject;
                [[event should] beKindOfClass:NSClassFromString(entityName)];
                [[event.eventType should] equal:PCF_PUSH_EVENT_TYPE_PUSH_NOTIFICATION_RECEIVED];
                [[event.receiptId should] equal:@"TEST_RECEIPT_ID"];
                [[event.deviceUuid should] equal:@"TEST_DEVICE_UUID"];
                [[event.geofenceId should] beNil];
                [[event.locationId should] beNil];
                [[event.eventTime shouldNot] beNil];
                [[event.status should] equal:@(PCFPushEventStatusNotPosted)];
            });

            it(@"should let you log when remote notifications are opened", ^{

                [PCFPushPersistentStorage setServerDeviceID:@"TEST_DEVICE_UUID"];

                [PCFPushAnalytics logOpenedRemoteNotification:@"TEST_RECEIPT_ID" parameters:parametersWithAnalyticsEnabled];

                NSArray *events = [PCFPushAnalyticsStorage.shared events];
                [[theValue(events.count) should] equal:theValue(1)];
                PCFPushAnalyticsEvent *event = events.lastObject;
                [[event should] beKindOfClass:NSClassFromString(entityName)];
                [[event.eventType should] equal:PCF_PUSH_EVENT_TYPE_PUSH_NOTIFICATION_OPENED];
                [[event.receiptId should] equal:@"TEST_RECEIPT_ID"];
                [[event.deviceUuid should] equal:@"TEST_DEVICE_UUID"];
                [[event.geofenceId should] beNil];
                [[event.locationId should] beNil];
                [[event.eventTime shouldNot] beNil];
                [[event.status should] equal:@(PCFPushEventStatusNotPosted)];
            });

            it(@"should let you log when geofence is triggered", ^{

                [PCFPushPersistentStorage setServerDeviceID:@"TEST_DEVICE_UUID"];

                [PCFPushAnalytics logTriggeredGeofenceId:57L locationId:923L parameters:parametersWithAnalyticsEnabled];

                NSArray *events = [PCFPushAnalyticsStorage.shared events];
                [[theValue(events.count) should] equal:theValue(1)];
                PCFPushAnalyticsEvent *event = events.lastObject;
                [[event should] beKindOfClass:NSClassFromString(entityName)];
                [[event.eventType should] equal:PCF_PUSH_EVENT_TYPE_PUSH_GEOFENCE_LOCATION_TRIGGER];
                [[event.receiptId should] beNil];
                [[event.deviceUuid should] equal:@"TEST_DEVICE_UUID"];
                [[event.geofenceId should] equal:@"57"];
                [[event.locationId should] equal:@"923"];
                [[event.eventTime shouldNot] beNil];
                [[event.status should] equal:@(PCFPushEventStatusNotPosted)];
            });
        });
    });

SPEC_END