//
// Created by DX181-XL on 15-04-15.
//

#import <CoreLocation/CoreLocation.h>
#import "Kiwi.h"
#import "PCFPushGeofenceData.h"
#import "PCFPushGeofenceHandler.h"
#import "NSObject+PCFJSONizable.h"
#import "PCFPushGeofencePersistentStore.h"
#import "PCFPushGeofenceDataList+Loaders.h"

typedef id (^StubBlock)(NSArray*);
static StubBlock geofenceWithId(int64_t expectedGeofenceId, PCFPushGeofenceData *geofence)
{
    return ^id(NSArray *params) {
        int64_t geofenceId = [params[0] longLongValue];
        if (geofenceId == expectedGeofenceId) {
            return geofence;
        }
        return nil;
    };
}

BOOL isAtLeastiOS8_2() {

    return [UILocalNotification instancesRespondToSelector:@selector(setAlertTitle:)] &&
            [UILocalNotification instancesRespondToSelector:@selector(setCategory:)];
}

SPEC_BEGIN(PCFPushGeofenceHandlerSpec)

    describe(@"PCFPushGeofenceHandler", ^{

        __block PCFPushGeofencePersistentStore *store;
        __block PCFPushGeofenceData *geofence;
        __block UIApplication *application;
        __block CLRegion *region;

        describe(@"handling geofence events", ^{

            beforeEach(^{
                store = [PCFPushGeofencePersistentStore mock];
                application = [UIApplication mock];
                NSData *data = loadTestFile([self class], @"geofence_one_item_persisted_3");
                NSError *error = nil;
                geofence = [PCFPushGeofenceData pcf_fromJSONData:data error:&error];
                [[geofence shouldNot] beNil];
                [[error should] beNil];
                region = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(0.0, 0.0) radius:0.0 identifier:@"PCF_3_66"];
                [UIApplication stub:@selector(sharedApplication) andReturn:application];
            });

            it(@"should require a persistent store", ^{
                [[theBlock(^{
                    [PCFPushGeofenceHandler processRegion:region store:nil];
                }) should] raiseWithName:NSInvalidArgumentException];
            });

            it(@"should do nothing if processing an empty event", ^{
                [[application shouldNot] receive:@selector(presentLocalNotificationNow:)];
                [[store shouldNot] receive:@selector(objectForKeyedSubscript:)];
                CLRegion *emptyRegion = [[CLRegion alloc] init];
                [PCFPushGeofenceHandler processRegion:emptyRegion store:store];
            });

            it(@"should trigger a local notification if processing a monitored geofence event", ^{
                [[application should] receive:@selector(presentLocalNotificationNow:)];
                [store stub:@selector(objectForKeyedSubscript:) withBlock:geofenceWithId(3L, geofence)];
                [PCFPushGeofenceHandler processRegion:region store:store];
            });

            it(@"should ignore geofence events with unknown IDs", ^{
                [[application shouldNot] receive:@selector(presentLocalNotificationNow:)];
                [store stub:@selector(objectForKeyedSubscript:) andReturn:nil];
                [PCFPushGeofenceHandler processRegion:region store:store];
            });

            it(@"should populate only iOS 7.0 fields on location notifications on devices < iOS 8.0", ^{

                [UILocalNotification stub: @selector(instancesRespondToSelector:) andReturn:theValue(NO)];

                UILocalNotification *expectedNotification = [[UILocalNotification alloc] init];
                expectedNotification.alertAction = geofence.data[@"ios"][@"alertAction"];
                expectedNotification.alertBody = geofence.data[@"ios"][@"alertBody"];
                expectedNotification.alertLaunchImage = geofence.data[@"ios"][@"alertLaunchImage"];
                expectedNotification.hasAction = [geofence.data[@"ios"][@"hasAction"] boolValue];
                expectedNotification.applicationIconBadgeNumber = [geofence.data[@"ios"][@"applicationIconBadgeNumber"] integerValue];
                expectedNotification.soundName = geofence.data[@"ios"][@"soundName"];
                expectedNotification.userInfo = geofence.data[@"ios"][@"userInfo"];

                if (isAtLeastiOS8_2()) {
                    [[expectedNotification.alertTitle should] beNil];
                    [[expectedNotification.category should] beNil];
                }

                [[application should] receive:@selector(presentLocalNotificationNow:) withArguments: expectedNotification, nil];
                [store stub:@selector(objectForKeyedSubscript:) withBlock:geofenceWithId(3L, geofence)];
                [PCFPushGeofenceHandler processRegion:region store:store];
            });

            it(@"should populate all the fields on location notifications on up-to-date devices", ^{

                if (!isAtLeastiOS8_2()) {
                    NSLog(@"Skipping test. iOS < 8.2");
                    return;
                }

                UILocalNotification *expectedNotification = [[UILocalNotification alloc] init];
                expectedNotification.alertTitle = geofence.data[@"ios"][@"alertTitle"]; // iOS 8.2+
                expectedNotification.category = geofence.data[@"ios"][@"category"]; // iOS 8.0+
                expectedNotification.alertAction = geofence.data[@"ios"][@"alertAction"];
                expectedNotification.alertBody = geofence.data[@"ios"][@"alertBody"];
                expectedNotification.alertLaunchImage = geofence.data[@"ios"][@"alertLaunchImage"];
                expectedNotification.hasAction = [geofence.data[@"ios"][@"hasAction"] boolValue];
                expectedNotification.applicationIconBadgeNumber = [geofence.data[@"ios"][@"applicationIconBadgeNumber"] integerValue];
                expectedNotification.soundName = geofence.data[@"ios"][@"soundName"];
                expectedNotification.userInfo = geofence.data[@"ios"][@"userInfo"];

                [[application should] receive:@selector(presentLocalNotificationNow:) withArguments: expectedNotification, nil];
                [store stub:@selector(objectForKeyedSubscript:) withBlock:geofenceWithId(3L, geofence)];
                [PCFPushGeofenceHandler processRegion:region store:store];
            });
        });
    });

SPEC_END