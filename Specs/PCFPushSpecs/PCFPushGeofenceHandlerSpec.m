//
// Created by DX181-XL on 15-04-15.
//

#import <CoreLocation/CoreLocation.h>
#import "Kiwi.h"
#import "PCFPushGeofenceData.h"
#import "PCFPushGeofenceHandler.h"
#import "PCFPushPersistentStorage.h"
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

static PCFPushGeofenceData *loadGeofence(Class testProjectClass, NSString *fileName)
{
    NSData *data = loadTestFile(testProjectClass, fileName);
    NSError *error = nil;
    return [PCFPushGeofenceData pcf_fromJSONData:data error:&error];
}

static BOOL isAtLeastiOS8_2()
{
    NSArray *iosVersion = [[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."];
    int versionMajor = [iosVersion[0] intValue];
    int versionMinor = [iosVersion[1] intValue];
    return (versionMajor > 8) || ((versionMajor == 8) && (versionMinor >= 2));
}

SPEC_BEGIN(PCFPushGeofenceHandlerSpec)

    beforeEach(^{
        [PCFPushPersistentStorage setTags:[NSSet set]];
    });

    describe(@"PCFPushGeofenceHandler", ^{

        __block PCFPushGeofencePersistentStore *store;
        __block PCFPushGeofenceData *geofence1EnterOrExit;
        __block PCFPushGeofenceData *geofence2Enter;
        __block PCFPushGeofenceData *geofence3Exit;
        __block PCFPushGeofenceData *geofence4EnterWithTags;
        __block UIApplication *application;
        __block CLRegion *region1;
        __block CLRegion *region2;
        __block CLRegion *region3;
        __block CLRegion *region4;

        describe(@"handling geofence events", ^{

            beforeEach(^{
                store = [PCFPushGeofencePersistentStore mock];
                application = [UIApplication mock];
                geofence1EnterOrExit = loadGeofence([self class], @"geofence_one_item_persisted_1");
                [[geofence1EnterOrExit shouldNot] beNil];
                geofence2Enter = loadGeofence([self class], @"geofence_one_item_persisted_2");
                [[geofence2Enter shouldNot] beNil];
                geofence3Exit = loadGeofence([self class], @"geofence_one_item_persisted_3");
                [[geofence3Exit shouldNot] beNil];
                geofence4EnterWithTags = loadGeofence([self class], @"geofence_one_item_persisted_4");
                [[geofence4EnterWithTags shouldNot] beNil];
                region1 = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(0.0, 0.0) radius:0.0 identifier:@"PCF_1_66"];
                region2 = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(0.0, 0.0) radius:0.0 identifier:@"PCF_2_66"];
                region3 = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(0.0, 0.0) radius:0.0 identifier:@"PCF_3_66"];
                region4 = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(0.0, 0.0) radius:0.0 identifier:@"PCF_4_66"];
                [UIApplication stub:@selector(sharedApplication) andReturn:application];
            });

            context(@"unknown state", ^{

                it(@"should not trigger a local notification at all ever if the state is unknown (1)", ^{
                    [[application shouldNot] receive:@selector(presentLocalNotificationNow:)];
                    [store stub:@selector(objectForKeyedSubscript:) withBlock:geofenceWithId(1L, geofence1EnterOrExit)];
                    [PCFPushGeofenceHandler processRegion:region1 store:store state:CLRegionStateUnknown];
                });

                it(@"should not trigger a local notification at all ever if the state is unknown (2)", ^{
                    [[application shouldNot] receive:@selector(presentLocalNotificationNow:)];
                    [store stub:@selector(objectForKeyedSubscript:) withBlock:geofenceWithId(2L, geofence2Enter)];
                    [PCFPushGeofenceHandler processRegion:region2 store:store state:CLRegionStateUnknown];
                });

                it(@"should not trigger a local notification at all ever if the state is unknown (3)", ^{
                    [[application shouldNot] receive:@selector(presentLocalNotificationNow:)];
                    [store stub:@selector(objectForKeyedSubscript:) withBlock:geofenceWithId(3L, geofence3Exit)];
                    [PCFPushGeofenceHandler processRegion:region3 store:store state:CLRegionStateUnknown];
                });

                it(@"should not trigger a local notification at all ever if the state is unknown (4)", ^{
                    [[application shouldNot] receive:@selector(presentLocalNotificationNow:)];
                    [store stub:@selector(objectForKeyedSubscript:) withBlock:geofenceWithId(4L, geofence3Exit)];
                    [PCFPushGeofenceHandler processRegion:region4 store:store state:CLRegionStateUnknown];
                });
            });

            context(@"entering a geofence", ^{

                it(@"should trigger a local notification with the enter_or_exit trigger type", ^{
                    [application stub:@selector(presentLocalNotificationNow:) withBlock:^id(NSArray *params) {
                        UILocalNotification *notification = params[0];
                        [[notification.userInfo[@"pivotal.push.geofence_trigger_condition"] should] equal:@"enter"];
                        return nil;
                    }];

                    [[application should] receive:@selector(presentLocalNotificationNow:)];
                    [store stub:@selector(objectForKeyedSubscript:) withBlock:geofenceWithId(1L, geofence1EnterOrExit)];
                    [PCFPushGeofenceHandler processRegion:region1 store:store state:CLRegionStateInside];
                });

                it(@"should trigger a local notification with the enter trigger type", ^{
                    [application stub:@selector(presentLocalNotificationNow:) withBlock:^id(NSArray *params) {
                        UILocalNotification *notification = params[0];
                        [[notification.userInfo[@"pivotal.push.geofence_trigger_condition"] should] equal:@"enter"];
                        return nil;
                    }];

                    [[application should] receive:@selector(presentLocalNotificationNow:)];
                    [store stub:@selector(objectForKeyedSubscript:) withBlock:geofenceWithId(2L, geofence2Enter)];
                    [PCFPushGeofenceHandler processRegion:region2 store:store state:CLRegionStateInside];
                });

                it(@"should not trigger a local notification with the exit trigger type", ^{
                    [[application shouldNot] receive:@selector(presentLocalNotificationNow:)];
                    [store stub:@selector(objectForKeyedSubscript:) withBlock:geofenceWithId(3L, geofence3Exit)];
                    [PCFPushGeofenceHandler processRegion:region3 store:store state:CLRegionStateInside];
                });
            });

            context(@"exiting a geofence", ^{

                it(@"should trigger a local notification with the enter_or_exit trigger type", ^{
                    [application stub:@selector(presentLocalNotificationNow:) withBlock:^id(NSArray *params) {
                        UILocalNotification *notification = params[0];
                        [[notification.userInfo[@"pivotal.push.geofence_trigger_condition"] should] equal:@"exit"];
                        return nil;
                    }];

                    [[application should] receive:@selector(presentLocalNotificationNow:)];
                    [store stub:@selector(objectForKeyedSubscript:) withBlock:geofenceWithId(1L, geofence1EnterOrExit)];
                    [PCFPushGeofenceHandler processRegion:region1 store:store state:CLRegionStateOutside];
                });

                it(@"should not trigger a local notification with the enter trigger type", ^{
                    [[application shouldNot] receive:@selector(presentLocalNotificationNow:)];
                    [store stub:@selector(objectForKeyedSubscript:) withBlock:geofenceWithId(2L, geofence2Enter)];
                    [PCFPushGeofenceHandler processRegion:region2 store:store state:CLRegionStateOutside];
                });

                it(@"should trigger a local notification with the exit trigger type", ^{
                    [application stub:@selector(presentLocalNotificationNow:) withBlock:^id(NSArray *params) {
                        UILocalNotification *notification = params[0];
                        [[notification.userInfo[@"pivotal.push.geofence_trigger_condition"] should] equal:@"exit"];
                        return nil;
                    }];

                    [[application should] receive:@selector(presentLocalNotificationNow:)];
                    [store stub:@selector(objectForKeyedSubscript:) withBlock:geofenceWithId(3L, geofence3Exit)];
                    [PCFPushGeofenceHandler processRegion:region3 store:store state:CLRegionStateOutside];
                });
            });

            context(@"tags", ^{

                it(@"should ignore geofences if the user is not subscribed to any tags", ^{
                    [[application shouldNot] receive:@selector(presentLocalNotificationNow:)];
                    [store stub:@selector(objectForKeyedSubscript:) withBlock:geofenceWithId(4L, geofence4EnterWithTags)];
                    [PCFPushGeofenceHandler processRegion:region4 store:store state:CLRegionStateInside];

                });

                it(@"should ignore geofences if the user is not subscribed to one of its tags", ^{
                    [PCFPushPersistentStorage setTags:[NSSet setWithArray:@[ @"TUESDAY", @"WEDNESDAY"]]];
                    [[application shouldNot] receive:@selector(presentLocalNotificationNow:)];
                    [store stub:@selector(objectForKeyedSubscript:) withBlock:geofenceWithId(4L, geofence4EnterWithTags)];
                    [PCFPushGeofenceHandler processRegion:region4 store:store state:CLRegionStateInside];

                });

                it(@"should trigger geofences if the user is subscribed to one of its tags", ^{
                    [PCFPushPersistentStorage setTags:[NSSet setWithArray:@[ @"THURSDAY", @"FRIDAY"]]];
                    [[application should] receive:@selector(presentLocalNotificationNow:)];
                    [store stub:@selector(objectForKeyedSubscript:) withBlock:geofenceWithId(4L, geofence4EnterWithTags)];
                    [PCFPushGeofenceHandler processRegion:region4 store:store state:CLRegionStateInside];
                });
            });

            it(@"should require a persistent store", ^{
                [[theBlock(^{
                    [PCFPushGeofenceHandler processRegion:region1 store:nil state:CLRegionStateInside];
                }) should] raiseWithName:NSInvalidArgumentException];
            });

            it(@"should do nothing if processing an empty event", ^{
                [[application shouldNot] receive:@selector(presentLocalNotificationNow:)];
                [[store shouldNot] receive:@selector(objectForKeyedSubscript:)];
                CLRegion *emptyRegion = [[CLRegion alloc] init];
                [PCFPushGeofenceHandler processRegion:emptyRegion store:store state:CLRegionStateInside];
            });

            it(@"should ignore geofence events with unknown IDs", ^{
                [[application shouldNot] receive:@selector(presentLocalNotificationNow:)];
                [store stub:@selector(objectForKeyedSubscript:) andReturn:nil];
                [PCFPushGeofenceHandler processRegion:region3 store:store state:CLRegionStateInside];
            });

            it(@"should populate only iOS 7.0 fields on location notifications on devices < iOS 8.0", ^{

                [UILocalNotification stub: @selector(instancesRespondToSelector:) andReturn:theValue(NO)];

                UILocalNotification *expectedNotification = [[UILocalNotification alloc] init];
                expectedNotification.alertAction = geofence3Exit.data[@"ios"][@"alertAction"];
                expectedNotification.alertBody = geofence3Exit.data[@"ios"][@"alertBody"];
                expectedNotification.alertLaunchImage = geofence3Exit.data[@"ios"][@"alertLaunchImage"];
                expectedNotification.hasAction = [geofence3Exit.data[@"ios"][@"hasAction"] boolValue];
                expectedNotification.applicationIconBadgeNumber = [geofence3Exit.data[@"ios"][@"applicationIconBadgeNumber"] integerValue];
                expectedNotification.soundName = geofence3Exit.data[@"ios"][@"soundName"];

                NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:geofence3Exit.data[@"ios"][@"userInfo"]];
                userInfo[@"pivotal.push.geofence_trigger_condition"] = @"exit";

                expectedNotification.userInfo = userInfo;

                if (isAtLeastiOS8_2()) {
                    [[expectedNotification.alertTitle should] beNil];
                    [[expectedNotification.category should] beNil];
                }

                [[application should] receive:@selector(presentLocalNotificationNow:) withArguments: expectedNotification, nil];
                [store stub:@selector(objectForKeyedSubscript:) withBlock:geofenceWithId(3L, geofence3Exit)];
                [PCFPushGeofenceHandler processRegion:region3 store:store state:CLRegionStateOutside];
            });

            it(@"should populate all the fields on location notifications on up-to-date devices", ^{

                if (!isAtLeastiOS8_2()) {
                    NSLog(@"Skipping test. iOS < 8.2");
                    return;
                }

                UILocalNotification *expectedNotification = [[UILocalNotification alloc] init];
                expectedNotification.alertTitle = geofence3Exit.data[@"ios"][@"alertTitle"]; // iOS 8.2+
                expectedNotification.category = geofence3Exit.data[@"ios"][@"category"]; // iOS 8.0+
                expectedNotification.alertAction = geofence3Exit.data[@"ios"][@"alertAction"];
                expectedNotification.alertBody = geofence3Exit.data[@"ios"][@"alertBody"];
                expectedNotification.alertLaunchImage = geofence3Exit.data[@"ios"][@"alertLaunchImage"];
                expectedNotification.hasAction = [geofence3Exit.data[@"ios"][@"hasAction"] boolValue];
                expectedNotification.applicationIconBadgeNumber = [geofence3Exit.data[@"ios"][@"applicationIconBadgeNumber"] integerValue];
                expectedNotification.soundName = geofence3Exit.data[@"ios"][@"soundName"];

                NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:geofence3Exit.data[@"ios"][@"userInfo"]];
                userInfo[@"pivotal.push.geofence_trigger_condition"] = @"exit";

                expectedNotification.userInfo = userInfo;

                [[application should] receive:@selector(presentLocalNotificationNow:) withArguments: expectedNotification, nil];
                [store stub:@selector(objectForKeyedSubscript:) withBlock:geofenceWithId(3L, geofence3Exit)];
                [PCFPushGeofenceHandler processRegion:region3 store:store state:CLRegionStateOutside];
            });
        });
    });

SPEC_END