//
//  PCFPushAnalyticsSpec.m
//  PCFPushPushSpec
//

#import "Kiwi.h"
#import <CoreData/CoreData.h>
#import "PCFPushErrorUtil.h"
#import "PCFPushAnalytics.h"
#import "PCFPushParameters.h"
#import "PCFPushSpecsHelper.h"
#import "PCFPushAnalyticsEvent.h"
#import "PCFPushAnalyticsStorage.h"
#import "PCFPushPersistentStorage.h"

SPEC_BEGIN(PCFPushAnalyticsSpec)

    __block PCFPushSpecsHelper *helper;
    __block PCFPushParameters *parametersWithAnalyticsEnabled;
    __block PCFPushParameters *parametersWithAnalyticsDisabled;

    beforeEach(^{
        helper = [[PCFPushSpecsHelper alloc] init];
        [PCFPushPersistentStorage reset];
        [helper setupAnalyticsStorage];
        [helper setupDefaultPLIST];
        parametersWithAnalyticsDisabled = [PCFPushParameters parametersWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"Pivotal-AnalyticsDisabled" ofType:@"plist"]];
        parametersWithAnalyticsEnabled = [PCFPushParameters defaultParameters];
        [PCFPushAnalytics resetAnalytics];
    });

    afterEach(^{
        [helper resetAnalyticsStorage];
        [helper reset];
        helper = nil;
    });

    describe(@"checking polling time", ^{

        it(@"it should never be polling time if analytics are disabled", ^{
           [[theValue([PCFPushAnalytics isAnalyticsPollingTime:parametersWithAnalyticsDisabled]) should] beNo];
        });

        context(@"when analytics are enabled", ^{

            it(@"should be polling time if the server version has not been fetched before", ^{
                [PCFPushPersistentStorage setServerVersionTimePolled:nil];
                [[theValue([PCFPushAnalytics isAnalyticsPollingTime:parametersWithAnalyticsEnabled]) should] beYes];
            });

            it(@"should be polling time if the server version has been fetched more than 1 minute ago (debug mode)", ^{
                [PCFPushPersistentStorage setServerVersionTimePolled:[NSDate dateWithTimeIntervalSince1970:0]];
                [NSDate stub:@selector(date) andReturn:[NSDate dateWithTimeIntervalSince1970:(60 + 1)]];
                [[theValue([PCFPushAnalytics isAnalyticsPollingTime:parametersWithAnalyticsEnabled]) should] beYes];
            });

            it(@"should not be polling time if the server version has been fetched less than 1 minute ago (debug mode)", ^{
                [PCFPushPersistentStorage setServerVersionTimePolled:[NSDate dateWithTimeIntervalSince1970:0]];
                [NSDate stub:@selector(date) andReturn:[NSDate dateWithTimeIntervalSince1970:(60 - 1)]];
                [[theValue([PCFPushAnalytics isAnalyticsPollingTime:parametersWithAnalyticsEnabled]) should] beNo];
            });
        });
    });

    describe(@"Logging an event", ^{

        __block NSString *entityName;

        beforeEach(^{
            entityName = NSStringFromClass(PCFPushAnalyticsEvent.class);
            [PCFPushPersistentStorage setServerVersion:@"1.3.2"];
            [NSDate stub:@selector(date) andReturn:[NSDate dateWithTimeIntervalSince1970:1337.0]];
        });

        describe(@"logging events", ^{

            it(@"should let you log an event successfully", ^{

                [PCFPushAnalytics logEvent:@"TEST_EVENT" parameters:parametersWithAnalyticsEnabled];

                NSArray *events = [PCFPushAnalyticsStorage.shared events];
                [[theValue(events.count) should] equal:theValue(1)];
                PCFPushAnalyticsEvent *event = events.lastObject;
                [[event should] beKindOfClass:NSClassFromString(entityName)];
                [[event.eventType should] equal:@"TEST_EVENT"];
                [[event.eventTime should] equal:@"1337000"];
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
                [[event.eventTime should] equal:@"1337000"];
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
                [[event.eventTime should] equal:@"1337000"];
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
                [[event.eventTime should] equal:@"1337000"];
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
                [[event.eventTime should] equal:@"1337000"];
                [[event.status should] equal:@(PCFPushEventStatusNotPosted)];
            });
        });
    });

    describe(@"checking the server version", ^{

        beforeEach(^{
            [PCFPushPersistentStorage setServerVersion:nil];
            [PCFPushPersistentStorage setServerVersionTimePolled:nil];
        });

        it(@"should enable analytics if the version request returns a new version", ^{

            [helper setupVersionRequestWithBlock:^(void (^successBlock)(NSString *), void (^oldVersionBlock)(), void (^errorBlock)(NSError *)) {
                successBlock(@"5.32.80");
            }];

            [[PCFPushAnalytics should] receive:@selector(prepareEventsDatabase)];

            [PCFPushAnalytics checkAnalytics:parametersWithAnalyticsEnabled];

            [[PCFPushPersistentStorage.serverVersion should] equal:@"5.32.80"];
            [[PCFPushPersistentStorage.serverVersionTimePolled shouldNot] beNil];
            [[theValue(parametersWithAnalyticsEnabled.areAnalyticsEnabledAndAvailable) should] beYes];
        });

        it(@"should disable analytics if the version request returns an old version", ^{

            [helper setupVersionRequestWithBlock:^(void (^successBlock)(NSString *), void (^oldVersionBlock)(), void (^errorBlock)(NSError *)) {
                oldVersionBlock();
            }];

            [[PCFPushAnalytics shouldNot] receive:@selector(prepareEventsDatabase)];

            [PCFPushAnalytics checkAnalytics:parametersWithAnalyticsEnabled];

            [[PCFPushPersistentStorage.serverVersion should] beNil];
            [[PCFPushPersistentStorage.serverVersionTimePolled shouldNot] beNil];
            [[theValue(parametersWithAnalyticsEnabled.areAnalyticsEnabledAndAvailable) should] beNo];
        });

        it(@"should do nothing if the version request fails", ^{

            [PCFPushPersistentStorage setServerVersion:@"1.0.0"];
            [PCFPushPersistentStorage setServerVersionTimePolled:[NSDate dateWithTimeIntervalSince1970:50]];


            [helper setupVersionRequestWithBlock:^(void (^successBlock)(NSString *), void (^oldVersionBlock)(), void (^errorBlock)(NSError *)) {
                errorBlock([PCFPushErrorUtil errorWithCode:0 localizedDescription:nil]);
            }];

            [[PCFPushAnalytics shouldNot] receive:@selector(prepareEventsDatabase)];

            [PCFPushAnalytics checkAnalytics:parametersWithAnalyticsEnabled];

            [[PCFPushPersistentStorage.serverVersion should] equal:@"1.0.0"];
            [[PCFPushPersistentStorage.serverVersionTimePolled should] equal:[NSDate dateWithTimeIntervalSince1970:50]];
            [[theValue(parametersWithAnalyticsEnabled.areAnalyticsEnabledAndAvailable) should] beNo];
        });
    });

    describe(@"preparing the events database", ^{

        it(@"should do nothing if the events database is empty", ^{
            [[PCFPushAnalyticsStorage.shared.events should] beEmpty];
            [PCFPushAnalytics prepareEventsDatabase];
            [[PCFPushAnalyticsStorage.shared.events should] beEmpty];
        });

        it(@"should set events with the 'posting' and 'posting error' statuses to 'not posted'", ^{

            [PCFPushPersistentStorage setServerVersion:@"1.3.2"];

            [PCFPushAnalytics logEvent:@"NOT_POSTED" parameters:parametersWithAnalyticsEnabled];
            [PCFPushAnalytics logEvent:@"POSTING" parameters:parametersWithAnalyticsEnabled];
            [PCFPushAnalytics logEvent:@"POSTED" parameters:parametersWithAnalyticsEnabled];
            [PCFPushAnalytics logEvent:@"POSTING_ERROR" parameters:parametersWithAnalyticsEnabled];

            NSString *entityName = NSStringFromClass(PCFPushAnalyticsEvent.class);

            PCFPushAnalyticsEvent *postingEvent = [PCFPushAnalyticsStorage.shared managedObjectsWithEntityName:entityName predicate:[NSPredicate predicateWithFormat:@"eventType == 'POSTING'"]][0];
            [PCFPushAnalyticsStorage.shared setEventsStatus:@[postingEvent] status:PCFPushEventStatusPosting];

            PCFPushAnalyticsEvent *postingErrorEvent = [PCFPushAnalyticsStorage.shared managedObjectsWithEntityName:entityName predicate:[NSPredicate predicateWithFormat:@"eventType == 'POSTING_ERROR'"]][0];
            [PCFPushAnalyticsStorage.shared setEventsStatus:@[postingErrorEvent] status:PCFPushEventStatusPostingError];

            PCFPushAnalyticsEvent *postedEvent = [PCFPushAnalyticsStorage.shared managedObjectsWithEntityName:entityName predicate:[NSPredicate predicateWithFormat:@"eventType == 'POSTED'"]][0];
            [PCFPushAnalyticsStorage.shared setEventsStatus:@[postedEvent] status:PCFPushEventStatusPosted];

            [[PCFPushAnalyticsStorage.shared.events should] haveCountOf:4];

            [PCFPushAnalytics prepareEventsDatabase];

            [[PCFPushAnalyticsStorage.shared.events should] haveCountOf:4];

            NSArray *notPostedEventsAfter = [PCFPushAnalyticsStorage.shared eventsWithStatus:PCFPushEventStatusNotPosted];
            [[notPostedEventsAfter should] haveCountOf:3];

            NSArray *postingEventsAfter = [PCFPushAnalyticsStorage.shared eventsWithStatus:PCFPushEventStatusPosting];
            [[postingEventsAfter should] beEmpty];

            NSArray *postingErrorEventsAfter = [PCFPushAnalyticsStorage.shared eventsWithStatus:PCFPushEventStatusPostingError];
            [[postingErrorEventsAfter should] beEmpty];

            NSArray *postedEventsAfter = [PCFPushAnalyticsStorage.shared eventsWithStatus:PCFPushEventStatusPosted];
            [[postedEventsAfter should] haveCountOf:1];
        });
    });

    describe(@"sending events", ^{

        beforeEach(^{
            [PCFPushPersistentStorage setServerVersion:@"1.3.2"];
        });

        it(@"should do nothing if analytics is disabled", ^{

            [PCFPushAnalytics logEvent:@"TEST_EVENT1" parameters:parametersWithAnalyticsEnabled];

            [helper setupAsyncRequestWithBlock:^(NSURLRequest *request, NSURLResponse **resultResponse, NSData **resultData, NSError **resultError) {
                fail(@"Should not have made request");
            }];

            [PCFPushAnalytics sendEventsWithParameters:parametersWithAnalyticsDisabled];
            [[PCFPushAnalyticsStorage.shared.events should] haveCountOf:1];
        });

        it(@"should do nothing if the events database is empty", ^{

            [helper setupAsyncRequestWithBlock:^(NSURLRequest *request, NSURLResponse **resultResponse, NSData **resultData, NSError **resultError) {
                fail(@"Should not have made request");
            }];

            [PCFPushAnalytics sendEventsWithParameters:parametersWithAnalyticsDisabled];
            [[PCFPushAnalyticsStorage.shared.events should] beEmpty];
        });

        it(@"should send events to the server and delete them after they are posted successfully", ^{

            __block BOOL didMakeRequest = NO;

            [helper setupAsyncRequestWithBlock:^(NSURLRequest *request, NSURLResponse **resultResponse, NSData **resultData, NSError **resultError) {
                didMakeRequest = YES;

                [[request.HTTPMethod should] equal:@"POST"];

                [[request.HTTPBody shouldNot] beNil];
                NSError *error;
                id json = [NSJSONSerialization JSONObjectWithData:request.HTTPBody options:0 error:&error];
                [[json shouldNot] beNil];
                [[error should] beNil];

                NSArray *events = PCFPushAnalyticsStorage.shared.events;
                [[events should] haveCountOf:3];
                [[[events[0] status] should] equal:@(PCFPushEventStatusPosting)];
                [[[events[1] status] should] equal:@(PCFPushEventStatusPosting)];
                [[[events[2] status] should] equal:@(PCFPushEventStatusPosting)];

                *resultResponse = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@""]  statusCode:200 HTTPVersion:nil headerFields:nil];
            }];

            [PCFPushAnalytics logEvent:@"TEST_EVENT1" parameters:parametersWithAnalyticsEnabled];
            [PCFPushAnalytics logEvent:@"TEST_EVENT2" parameters:parametersWithAnalyticsEnabled];
            [PCFPushAnalytics logEvent:@"TEST_EVENT3" parameters:parametersWithAnalyticsEnabled];
            [[PCFPushAnalyticsStorage.shared.events should] haveCountOf:3];

            [PCFPushAnalytics sendEventsWithParameters:parametersWithAnalyticsEnabled];

            [[theValue(didMakeRequest) should] beTrue];
            [[PCFPushAnalyticsStorage.shared.events should] beEmpty];
        });

        it(@"should mark events with an error status if they fail to send", ^{

            __block BOOL didMakeRequest = NO;

            [helper setupAsyncRequestWithBlock:^(NSURLRequest *request, NSURLResponse **resultResponse, NSData **resultData, NSError **resultError) {
                didMakeRequest = YES;

                NSArray *events = PCFPushAnalyticsStorage.shared.events;
                [[events should] haveCountOf:3];
                [[[events[0] status] should] equal:@(PCFPushEventStatusPosting)];
                [[[events[1] status] should] equal:@(PCFPushEventStatusPosting)];
                [[[events[2] status] should] equal:@(PCFPushEventStatusPosting)];

                *resultResponse = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@""]  statusCode:500 HTTPVersion:nil headerFields:nil];
            }];

            [PCFPushAnalytics logEvent:@"TEST_EVENT1" parameters:parametersWithAnalyticsEnabled];
            [PCFPushAnalytics logEvent:@"TEST_EVENT2" parameters:parametersWithAnalyticsEnabled];
            [PCFPushAnalytics logEvent:@"TEST_EVENT3" parameters:parametersWithAnalyticsEnabled];
            [[PCFPushAnalyticsStorage.shared.events should] haveCountOf:3];

            [PCFPushAnalytics sendEventsWithParameters:parametersWithAnalyticsEnabled];

            [[theValue(didMakeRequest) should] beTrue];
            NSArray *events = PCFPushAnalyticsStorage.shared.events;
            [[events should] haveCountOf:3];
            [[[events[0] status] should] equal:@(PCFPushEventStatusPostingError)];
            [[[events[1] status] should] equal:@(PCFPushEventStatusPostingError)];
            [[[events[2] status] should] equal:@(PCFPushEventStatusPostingError)];
        });
    });

SPEC_END