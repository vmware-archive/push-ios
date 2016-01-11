//
// Created by DX181-XL on 15-04-15.
//

#import <CoreLocation/CoreLocation.h>
#import "Kiwi.h"
#import "PCFPushAnalytics.h"
#import "PCFPushParameters.h"
#import "PCFPushGeofenceData.h"
#import "PCFPushGeofenceEngine.h"
#import "PCFPushGeofenceHandler.h"
#import "NSObject+PCFJSONizable.h"
#import "PCFPushPersistentStorage.h"
#import "PCFPushGeofenceLocationMap.h"
#import "PCFPushGeofencePersistentStore.h"
#import "PCFPushGeofenceDataList+Loaders.h"
#import "PCFPushSpecsHelper.h"

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
    return [PCFPushGeofenceData pcfPushFromJSONData:data error:&error];
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
        [PCFPushPersistentStorage setTags:[NSSet<NSString*> set]];
    });

    describe(@"PCFPushGeofenceHandler", ^{

        __block PCFPushSpecsHelper *helper;
        __block PCFPushGeofenceEngine *engine;
        __block PCFPushGeofencePersistentStore *store;
        __block PCFPushGeofenceData *geofence2Enter;
        __block PCFPushGeofenceData *geofence3Exit;
        __block PCFPushGeofenceData *geofence4EnterWithTags;
        __block PCFPushGeofenceData *geofence5EnterThreeLocations;
        __block PCFPushGeofenceData *geofence6EmptyiOSData;
        __block PCFPushGeofenceData *geofence7NulliOSData;
        __block PCFPushGeofenceLocationMap *expectedMapToClear;
        __block UIApplication *application;
        __block CLRegion *region2;
        __block CLRegion *region3;
        __block CLRegion *region4;
        __block CLRegion *region5;
        __block CLRegion *region6;
        __block CLRegion *region7;
        __block CLRegion *badRegion;
        __block PCFPushParameters *parametersWithAnalyticsEnabled;
        __block PCFPushParameters *parametersWithAnalyticsDisabled;

        describe(@"handling geofence events", ^{

            beforeEach(^{
                helper = [[PCFPushSpecsHelper alloc] init];
                store = [PCFPushGeofencePersistentStore mock];
                engine = [PCFPushGeofenceEngine mock];
                application = [UIApplication mock];
                geofence2Enter = loadGeofence([self class], @"geofence_one_item_persisted_2");
                [[geofence2Enter shouldNot] beNil];
                geofence3Exit = loadGeofence([self class], @"geofence_one_item_persisted_3");
                [[geofence3Exit shouldNot] beNil];
                geofence4EnterWithTags = loadGeofence([self class], @"geofence_one_item_persisted_4");
                [[geofence4EnterWithTags shouldNot] beNil];
                geofence5EnterThreeLocations = loadGeofence([self class], @"geofence_one_item_persisted_5");
                [[geofence5EnterThreeLocations shouldNot] beNil];
                geofence6EmptyiOSData = loadGeofence([self class], @"geofence_one_item_persisted_6");
                [[geofence6EmptyiOSData shouldNot] beNil];
                geofence7NulliOSData = loadGeofence([self class], @"geofence_one_item_persisted_7");
                [[geofence7NulliOSData shouldNot] beNil];
                region2 = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(0.0, 0.0) radius:0.0 identifier:@"PCF_2_66"];
                region3 = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(0.0, 0.0) radius:0.0 identifier:@"PCF_3_66"];
                region4 = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(0.0, 0.0) radius:0.0 identifier:@"PCF_4_66"];
                region5 = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(0.0, 0.0) radius:0.0 identifier:@"PCF_5_67"];
                region6 = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(0.0, 0.0) radius:0.0 identifier:@"PCF_6_68"];
                region7 = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(0.0, 0.0) radius:0.0 identifier:@"PCF_7_70"];
                badRegion = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(0.0, 0.0) radius:0.0 identifier:@"XXXXXXXX"];
                expectedMapToClear = [PCFPushGeofenceLocationMap map];
                [UIApplication stub:@selector(sharedApplication) andReturn:application];
                [NSDate stub:@selector(date) andReturn:[NSDate dateWithTimeIntervalSince1970:0]]; // Pretend the time is always zero so that nothing is expired.
                [PCFPushPersistentStorage reset];
                [helper setupDefaultPLIST];
                parametersWithAnalyticsDisabled = [PCFPushParameters parametersWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"Pivotal-AnalyticsDisabled" ofType:@"plist"]];
                parametersWithAnalyticsEnabled = [PCFPushParameters defaultParameters];
            });

            afterEach(^{
                [helper reset];
            });

            context(@"unknown state", ^{

                it(@"should not trigger a local notification at all ever if the state is unknown (2)", ^{
                    [[engine shouldNot] receive:@selector(clearLocations:withTags:)];
                    [[application shouldNot] receive:@selector(presentLocalNotificationNow:)];
                    [store stub:@selector(objectForKeyedSubscript:) withBlock:geofenceWithId(2L, geofence2Enter)];
                    [[PCFPushAnalytics shouldNot] receive:@selector(logTriggeredGeofenceId:locationId:parameters:)];
                    [PCFPushGeofenceHandler processRegion:region2 store:store engine:engine state:CLRegionStateUnknown parameters:parametersWithAnalyticsEnabled];
                });

                it(@"should not trigger a local notification at all ever if the state is unknown (3)", ^{
                    [[engine shouldNot] receive:@selector(clearLocations:withTags:)];
                    [[application shouldNot] receive:@selector(presentLocalNotificationNow:)];
                    [store stub:@selector(objectForKeyedSubscript:) withBlock:geofenceWithId(3L, geofence3Exit)];
                    [[PCFPushAnalytics shouldNot] receive:@selector(logTriggeredGeofenceId:locationId:parameters:)];
                    [PCFPushGeofenceHandler processRegion:region3 store:store engine:engine state:CLRegionStateUnknown parameters:parametersWithAnalyticsEnabled];
                });

                it(@"should not trigger a local notification at all ever if the state is unknown (4)", ^{
                    [[engine shouldNot] receive:@selector(clearLocations:withTags:)];
                    [[application shouldNot] receive:@selector(presentLocalNotificationNow:)];
                    [store stub:@selector(objectForKeyedSubscript:) withBlock:geofenceWithId(4L, geofence3Exit)];
                    [[PCFPushAnalytics shouldNot] receive:@selector(logTriggeredGeofenceId:locationId:parameters:)];
                    [PCFPushGeofenceHandler processRegion:region4 store:store engine:engine state:CLRegionStateUnknown parameters:parametersWithAnalyticsEnabled];
                });
            });

            context(@"entering a geofence", ^{

                it(@"should trigger a local notification with the enter trigger type (analytics on)", ^{
                    [application stub:@selector(presentLocalNotificationNow:) withBlock:^id(NSArray *params) {
                        UILocalNotification *notification = params[0];
                        [[notification.userInfo[@"pivotal.push.geofence_trigger_condition"] should] equal:@"enter"];
                        return nil;
                    }];

                    [expectedMapToClear put:geofence2Enter locationIndex:0];
                    [[engine should] receive:@selector(clearLocations:withTags:) withArguments:expectedMapToClear, nil];
                    [[application should] receive:@selector(presentLocalNotificationNow:)];
                    [store stub:@selector(objectForKeyedSubscript:) withBlock:geofenceWithId(2L, geofence2Enter)];
                    [[PCFPushAnalytics should] receive:@selector(logTriggeredGeofenceId:locationId:parameters:) withArguments:theValue(2L), theValue(66L), any(), nil];
                    [[PCFPushAnalytics should] receive:@selector(sendEventsWithParameters:)];
                    [PCFPushGeofenceHandler processRegion:region2 store:store engine:engine state:CLRegionStateInside parameters:parametersWithAnalyticsEnabled];
                });

                it(@"should trigger a local notification with the enter trigger type (analytics off)", ^{
                    [application stub:@selector(presentLocalNotificationNow:) withBlock:^id(NSArray *params) {
                        UILocalNotification *notification = params[0];
                        [[notification.userInfo[@"pivotal.push.geofence_trigger_condition"] should] equal:@"enter"];
                        return nil;
                    }];

                    [expectedMapToClear put:geofence2Enter locationIndex:0];
                    [[engine should] receive:@selector(clearLocations:withTags:) withArguments:expectedMapToClear, nil];
                    [[application should] receive:@selector(presentLocalNotificationNow:)];
                    [store stub:@selector(objectForKeyedSubscript:) withBlock:geofenceWithId(2L, geofence2Enter)];
                    [helper setupDefaultPLISTWithFile:@"Pivotal-AnalyticsDisabled"];
                    [[PCFPushAnalytics shouldNot] receive:@selector(logTriggeredGeofenceId:locationId:parameters:)];
                    [[PCFPushAnalytics shouldNot] receive:@selector(sendEventsWithParameters:)];
                    [PCFPushGeofenceHandler processRegion:region2 store:store engine:engine state:CLRegionStateInside parameters:parametersWithAnalyticsDisabled];
                });

                it(@"should not trigger a local notification with the exit trigger type", ^{
                    [[engine shouldNot] receive:@selector(clearLocations:withTags:)];
                    [[application shouldNot] receive:@selector(presentLocalNotificationNow:)];
                    [store stub:@selector(objectForKeyedSubscript:) withBlock:geofenceWithId(3L, geofence3Exit)];
                    [[PCFPushAnalytics shouldNot] receive:@selector(logTriggeredGeofenceId:locationId:parameters:)];
                    [[PCFPushAnalytics shouldNot] receive:@selector(sendEventsWithParameters:)];
                    [PCFPushGeofenceHandler processRegion:region3 store:store engine:engine state:CLRegionStateInside parameters:parametersWithAnalyticsEnabled];
                });
            });

            context(@"exiting a geofence", ^{

                it(@"should not trigger a local notification with the enter trigger type", ^{
                    [[engine shouldNot] receive:@selector(clearLocations:withTags:)];
                    [[application shouldNot] receive:@selector(presentLocalNotificationNow:)];
                    [store stub:@selector(objectForKeyedSubscript:) withBlock:geofenceWithId(2L, geofence2Enter)];
                    [[PCFPushAnalytics shouldNot] receive:@selector(logTriggeredGeofenceId:locationId:parameters:)];
                    [[PCFPushAnalytics shouldNot] receive:@selector(sendEventsWithParameters:)];
                    [PCFPushGeofenceHandler processRegion:region2 store:store engine:engine state:CLRegionStateOutside parameters:parametersWithAnalyticsEnabled];
                });

                it(@"should trigger a local notification with the exit trigger type", ^{
                    [application stub:@selector(presentLocalNotificationNow:) withBlock:^id(NSArray *params) {
                        UILocalNotification *notification = params[0];
                        [[notification.userInfo[@"pivotal.push.geofence_trigger_condition"] should] equal:@"exit"];
                        return nil;
                    }];

                    [expectedMapToClear put:geofence3Exit locationIndex:0];
                    [[engine should] receive:@selector(clearLocations:withTags:) withArguments:expectedMapToClear, nil];
                    [[application should] receive:@selector(presentLocalNotificationNow:)];
                    [store stub:@selector(objectForKeyedSubscript:) withBlock:geofenceWithId(3L, geofence3Exit)];
                    [[PCFPushAnalytics should] receive:@selector(logTriggeredGeofenceId:locationId:parameters:) withArguments:theValue(3L), theValue(66L), any(), nil];
                    [[PCFPushAnalytics should] receive:@selector(sendEventsWithParameters:)];
                    [PCFPushGeofenceHandler processRegion:region3 store:store engine:engine state:CLRegionStateOutside parameters:parametersWithAnalyticsEnabled];
                });
            });

            context(@"tags", ^{

                it(@"should ignore geofences if the user is not subscribed to any tags", ^{
                    [[engine shouldNot] receive:@selector(clearLocations:withTags:)];
                    [[application shouldNot] receive:@selector(presentLocalNotificationNow:)];
                    [store stub:@selector(objectForKeyedSubscript:) withBlock:geofenceWithId(4L, geofence4EnterWithTags)];
                    [[PCFPushAnalytics shouldNot] receive:@selector(logTriggeredGeofenceId:locationId:parameters:)];
                    [[PCFPushAnalytics shouldNot] receive:@selector(sendEventsWithParameters:)];
                    [PCFPushGeofenceHandler processRegion:region4 store:store engine:engine state:CLRegionStateInside parameters:parametersWithAnalyticsEnabled];
                });

                it(@"should ignore geofences if the user is not subscribed to one of its tags", ^{
                    [PCFPushPersistentStorage setTags:[NSSet<NSString*> setWithArray:@[ @"TUESDAY", @"WEDNESDAY"]]];
                    [[engine shouldNot] receive:@selector(clearLocations:withTags:)];
                    [[application shouldNot] receive:@selector(presentLocalNotificationNow:)];
                    [store stub:@selector(objectForKeyedSubscript:) withBlock:geofenceWithId(4L, geofence4EnterWithTags)];
                    [[PCFPushAnalytics shouldNot] receive:@selector(logTriggeredGeofenceId:locationId:parameters:)];
                    [[PCFPushAnalytics shouldNot] receive:@selector(sendEventsWithParameters:)];
                    [PCFPushGeofenceHandler processRegion:region4 store:store engine:engine state:CLRegionStateInside parameters:parametersWithAnalyticsEnabled];
                });

                it(@"should trigger geofences if the user is subscribed to one of its tags", ^{
                    [PCFPushPersistentStorage setTags:[NSSet<NSString*> setWithArray:@[ @"THURSDAY", @"FRIDAY"]]];
                    [expectedMapToClear put:geofence4EnterWithTags locationIndex:0];
                    [[engine should] receive:@selector(clearLocations:withTags:) withArguments:expectedMapToClear, nil];
                    [[application should] receive:@selector(presentLocalNotificationNow:)];
                    [store stub:@selector(objectForKeyedSubscript:) withBlock:geofenceWithId(4L, geofence4EnterWithTags)];
                    [[PCFPushAnalytics should] receive:@selector(logTriggeredGeofenceId:locationId:parameters:) withArguments:theValue(4L), theValue(66L), any(), nil];
                    [[PCFPushAnalytics should] receive:@selector(sendEventsWithParameters:)];
                    [PCFPushGeofenceHandler processRegion:region4 store:store engine:engine state:CLRegionStateInside parameters:parametersWithAnalyticsEnabled];
                });
            });

            context(@"expired geofences need to be cleared", ^{

                beforeEach(^{
                    NSDate *fakeDate = [NSDate dateWithTimeIntervalSince1970:991142744.274]; // Tue May 29 2001
                    [NSDate stub:@selector(date) andReturn:fakeDate];
                });

                it(@"should not trigger when entering a location that has expired (in a geofence with only one location)", ^{
                    [expectedMapToClear put:geofence2Enter locationIndex:0];
                    [[engine should] receive:@selector(clearLocations:withTags:) withArguments:expectedMapToClear, nil];
                    [[application shouldNot] receive:@selector(presentLocalNotificationNow:)];
                    [store stub:@selector(objectForKeyedSubscript:) withBlock:geofenceWithId(2L, geofence2Enter)];
                    [[PCFPushAnalytics shouldNot] receive:@selector(logTriggeredGeofenceId:locationId:parameters:)];
                    [[PCFPushAnalytics shouldNot] receive:@selector(sendEventsWithParameters:)];
                    [PCFPushGeofenceHandler processRegion:region2 store:store engine:engine state:CLRegionStateInside parameters:parametersWithAnalyticsEnabled];
                });

                it(@"should not trigger when entering a location that has expired (in a geofence with several locations)", ^{
                    [expectedMapToClear put:geofence5EnterThreeLocations locationIndex:0];
                    [expectedMapToClear put:geofence5EnterThreeLocations locationIndex:1];
                    [expectedMapToClear put:geofence5EnterThreeLocations locationIndex:2];
                    [[engine should] receive:@selector(clearLocations:withTags:) withArguments:expectedMapToClear, nil];
                    [[application shouldNot] receive:@selector(presentLocalNotificationNow:)];
                    [store stub:@selector(objectForKeyedSubscript:) withBlock:geofenceWithId(5L, geofence5EnterThreeLocations)];
                    [[PCFPushAnalytics shouldNot] receive:@selector(logTriggeredGeofenceId:locationId:parameters:)];
                    [[PCFPushAnalytics shouldNot] receive:@selector(sendEventsWithParameters:)];
                    [PCFPushGeofenceHandler processRegion:region5 store:store engine:engine state:CLRegionStateInside parameters:parametersWithAnalyticsEnabled];
                });

                it(@"should not trigger when exiting a location that has expired (in a geofence with only one location)", ^{
                    [expectedMapToClear put:geofence3Exit locationIndex:0];
                    [[engine should] receive:@selector(clearLocations:withTags:) withArguments:expectedMapToClear, nil];
                    [[application shouldNot] receive:@selector(presentLocalNotificationNow:)];
                    [store stub:@selector(objectForKeyedSubscript:) withBlock:geofenceWithId(3L, geofence3Exit)];
                    [[PCFPushAnalytics shouldNot] receive:@selector(logTriggeredGeofenceId:locationId:parameters:)];
                    [[PCFPushAnalytics shouldNot] receive:@selector(sendEventsWithParameters:)];
                    [PCFPushGeofenceHandler processRegion:region3 store:store engine:engine state:CLRegionStateOutside parameters:parametersWithAnalyticsEnabled];
                });
            });

            it(@"should require a persistent store", ^{
                [[theBlock(^{
                    [PCFPushGeofenceHandler processRegion:region2 store:nil engine:engine state:CLRegionStateInside parameters:parametersWithAnalyticsEnabled];
                }) should] raiseWithName:NSInvalidArgumentException];
            });

            it(@"should require an engine", ^{
                [[theBlock(^{
                    [PCFPushGeofenceHandler processRegion:region2 store:store engine:nil state:CLRegionStateInside parameters:parametersWithAnalyticsEnabled];
                }) should] raiseWithName:NSInvalidArgumentException];
            });

            it(@"should do nothing if processing an empty event", ^{
                [[engine shouldNot] receive:@selector(clearLocations:withTags:)];
                [[application shouldNot] receive:@selector(presentLocalNotificationNow:)];
                [[store shouldNot] receive:@selector(objectForKeyedSubscript:)];
                [[PCFPushAnalytics shouldNot] receive:@selector(logTriggeredGeofenceId:locationId:parameters:)];
                CLRegion *emptyRegion = [[CLRegion alloc] init];
                [PCFPushGeofenceHandler processRegion:emptyRegion store:store engine:engine state:CLRegionStateInside parameters:parametersWithAnalyticsEnabled];
            });

            it(@"should ignore geofence events for regions with bad identifiers", ^{
                [[engine shouldNot] receive:@selector(clearLocations:withTags:)];
                [[application shouldNot] receive:@selector(presentLocalNotificationNow:)];
                [[store shouldNot] receive:@selector(objectForKeyedSubscript:)];
                [[PCFPushAnalytics shouldNot] receive:@selector(logTriggeredGeofenceId:locationId:parameters:)];
                [[PCFPushAnalytics shouldNot] receive:@selector(sendEventsWithParameters:)];
                [PCFPushGeofenceHandler processRegion:badRegion store:store engine:engine state:CLRegionStateInside parameters:parametersWithAnalyticsEnabled];
            });

            it(@"should ignore geofence events for non-existent objects", ^{
                [[engine shouldNot] receive:@selector(clearLocations:withTags:)];
                [[application shouldNot] receive:@selector(presentLocalNotificationNow:)];
                [store stub:@selector(objectForKeyedSubscript:) andReturn:nil];
                [[PCFPushAnalytics shouldNot] receive:@selector(logTriggeredGeofenceId:locationId:parameters:)];
                [[PCFPushAnalytics shouldNot] receive:@selector(sendEventsWithParameters:)];
                [PCFPushGeofenceHandler processRegion:region3 store:store engine:engine state:CLRegionStateInside parameters:parametersWithAnalyticsEnabled];
            });

            it(@"should not populate fields with nil values", ^{

                UILocalNotification *expectedNotification = [[UILocalNotification alloc] init];
                expectedNotification.alertAction = nil;
                expectedNotification.alertBody = nil;
                expectedNotification.alertLaunchImage = nil;
                expectedNotification.hasAction = NO;
                expectedNotification.applicationIconBadgeNumber = 0;
                expectedNotification.soundName = nil;

                expectedNotification.userInfo =  @{@"pivotal.push.geofence_trigger_condition" : @"enter"};

                if (isAtLeastiOS8_2()) {
                    expectedNotification.alertTitle = nil;
                    expectedNotification.category = nil;
                }

                [expectedMapToClear put:geofence6EmptyiOSData locationIndex:0];
                [[engine should] receive:@selector(clearLocations:withTags:) withArguments:expectedMapToClear, nil];
                [[application should] receive:@selector(presentLocalNotificationNow:) withArguments:expectedNotification, nil];
                [store stub:@selector(objectForKeyedSubscript:) withBlock:geofenceWithId(6L, geofence6EmptyiOSData)];
                [[PCFPushAnalytics should] receive:@selector(logTriggeredGeofenceId:locationId:parameters:) withArguments:theValue(6L), theValue(68L), any(), nil];
                [[PCFPushAnalytics should] receive:@selector(sendEventsWithParameters:)];
                [PCFPushGeofenceHandler processRegion:region6 store:store engine:engine state:CLRegionStateInside parameters:parametersWithAnalyticsEnabled];
            });

            it(@"should not populate fields with NSNull values", ^{

                UILocalNotification *expectedNotification = [[UILocalNotification alloc] init];
                expectedNotification.alertAction = nil;
                expectedNotification.alertBody = nil;
                expectedNotification.alertLaunchImage = nil;
                expectedNotification.hasAction = NO;
                expectedNotification.applicationIconBadgeNumber = 0;
                expectedNotification.soundName = nil;

                expectedNotification.userInfo =  @{@"pivotal.push.geofence_trigger_condition" : @"enter"};

                if (isAtLeastiOS8_2()) {
                    expectedNotification.alertTitle = nil;
                    expectedNotification.category = nil;
                }

                [expectedMapToClear put:geofence7NulliOSData locationIndex:0];
                [[engine should] receive:@selector(clearLocations:withTags:) withArguments:expectedMapToClear, nil];
                [[application should] receive:@selector(presentLocalNotificationNow:) withArguments:expectedNotification, nil];
                [store stub:@selector(objectForKeyedSubscript:) withBlock:geofenceWithId(7L, geofence7NulliOSData)];
                [[PCFPushAnalytics should] receive:@selector(logTriggeredGeofenceId:locationId:parameters:) withArguments:theValue(7L), theValue(70L), any(), nil];
                [[PCFPushAnalytics should] receive:@selector(sendEventsWithParameters:)];
                [PCFPushGeofenceHandler processRegion:region7 store:store engine:engine state:CLRegionStateInside parameters:parametersWithAnalyticsEnabled];
            });

            it(@"should populate only iOS 7.0 fields on location notifications on devices < iOS 8.0", ^{

                [PCFPushGeofenceHandler stub:@selector(localNotificationRespondsToSetAlertTitle:) andReturn:theValue(NO)];
                [PCFPushGeofenceHandler stub:@selector(localNotificationRespondsToSetCategory:) andReturn:theValue(NO)];

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

                [expectedMapToClear put:geofence3Exit locationIndex:0];
                [[engine should] receive:@selector(clearLocations:withTags:) withArguments:expectedMapToClear, nil];
                [[application should] receive:@selector(presentLocalNotificationNow:) withArguments: expectedNotification, nil];
                [store stub:@selector(objectForKeyedSubscript:) withBlock:geofenceWithId(3L, geofence3Exit)];
                [[PCFPushAnalytics should] receive:@selector(logTriggeredGeofenceId:locationId:parameters:) withArguments:theValue(3L), theValue(66L), any(), nil];
                [[PCFPushAnalytics should] receive:@selector(sendEventsWithParameters:)];
                [PCFPushGeofenceHandler processRegion:region3 store:store engine:engine state:CLRegionStateOutside parameters:parametersWithAnalyticsEnabled];
            });

            it(@"should populate all the fields on location notifications on up-to-date devices", ^{

                if (!isAtLeastiOS8_2()) {
                    NSLog(@"Skipping test. iOS < 8.2");
                    return;
                }

                [PCFPushGeofenceHandler stub:@selector(localNotificationRespondsToSetAlertTitle:) andReturn:theValue(YES)];
                [PCFPushGeofenceHandler stub:@selector(localNotificationRespondsToSetCategory:) andReturn:theValue(YES)];

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

                [expectedMapToClear put:geofence3Exit locationIndex:0];
                [[engine should] receive:@selector(clearLocations:withTags:) withArguments:expectedMapToClear, nil];
                [[application should] receive:@selector(presentLocalNotificationNow:) withArguments: expectedNotification, nil];
                [store stub:@selector(objectForKeyedSubscript:) withBlock:geofenceWithId(3L, geofence3Exit)];
                [[PCFPushAnalytics should] receive:@selector(logTriggeredGeofenceId:locationId:parameters:) withArguments:theValue(3L), theValue(66L), any(), nil];
                [[PCFPushAnalytics should] receive:@selector(sendEventsWithParameters:)];
                [PCFPushGeofenceHandler processRegion:region3 store:store engine:engine state:CLRegionStateOutside parameters:parametersWithAnalyticsEnabled];
            });
        });
    });

SPEC_END