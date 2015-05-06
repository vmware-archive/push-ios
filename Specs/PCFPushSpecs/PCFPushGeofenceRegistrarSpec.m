//
// Created by DX181-XL on 15-04-15.
//

#import "Kiwi.h"
#import "PCFPushGeofenceRegistrar.h"
#import "PCFPushGeofenceLocationMap.h"
#import "PCFPushGeofenceDataList.h"
#import "PCFPushGeofenceDataList+Loaders.h"
#import <CoreLocation/CoreLocation.h>

SPEC_BEGIN(PCFPushGeofenceRegistrarSpec)

describe(@"PCFPushGeofenceRegistrar", ^{

    __block PCFPushGeofenceRegistrar *registrar;
    __block CLLocationManager *locationManager;
    __block PCFPushGeofenceDataList *oneItemGeofenceList;
    __block PCFPushGeofenceLocationMap *oneItemGeofenceMap;

    beforeEach(^{
        locationManager = [CLLocationManager mock];
        oneItemGeofenceList = loadGeofenceList([self class], @"geofence_one_item");
        oneItemGeofenceMap = [PCFPushGeofenceLocationMap map];
        [oneItemGeofenceMap put:oneItemGeofenceList[@7L] locationIndex:0];
    });

    it(@"should be initializable", ^{
        registrar = [[PCFPushGeofenceRegistrar alloc] initWithLocationManager:locationManager];
        [[registrar shouldNot] beNil];
    });

    it(@"should require a location manager", ^{
        [[theBlock(^{
            [[PCFPushGeofenceRegistrar alloc] initWithLocationManager:nil];
        }) should] raise];
    });

    it(@"should require hardware support", ^{
        registrar = [[PCFPushGeofenceRegistrar alloc] initWithLocationManager:locationManager];
        [CLLocationManager stub:@selector(isMonitoringAvailableForClass:) andReturn:theValue(NO)];
        [[locationManager shouldNot] receive:@selector(startMonitoringForRegion:)];
        [[locationManager shouldNot] receive:@selector(requestStateForRegion:)];
        [registrar registerGeofences:oneItemGeofenceMap list:oneItemGeofenceList];
    });

    context(@"registering geofences", ^{

        beforeEach(^{
            registrar = [[PCFPushGeofenceRegistrar alloc] initWithLocationManager:locationManager];
            [CLLocationManager stub:@selector(isMonitoringAvailableForClass:) andReturn:theValue(YES)];
        });

        it(@"should do nothing if given nil lists", ^{
            [[locationManager shouldNot] receive:@selector(startMonitoringForRegion:)];
            [[locationManager shouldNot] receive:@selector(requestStateForRegion:)];
            [registrar registerGeofences:nil list:nil];
        });

        it(@"should do nothing if given empty lists", ^{
            PCFPushGeofenceLocationMap *emptyMap = [PCFPushGeofenceLocationMap map];
            [[locationManager shouldNot] receive:@selector(startMonitoringForRegion:)];
            [[locationManager shouldNot] receive:@selector(requestStateForRegion:)];
            [registrar registerGeofences:emptyMap list:nil];
        });

        it(@"should be able to monitor a list with one item", ^{
            CLLocationCoordinate2D center = CLLocationCoordinate2DMake(53.5, -91.5);
            CLLocationDistance radius = 120;
            NSString *identifier = @"PCF_7_66";
            CLCircularRegion *region = [[CLCircularRegion alloc] initWithCenter:center radius:radius identifier:identifier];
            [[locationManager should] receive:@selector(startMonitoringForRegion:) withArguments:region, nil];
            [[locationManager should] receive:@selector(requestStateForRegion:) withArguments:region, nil];
            [registrar registerGeofences:oneItemGeofenceMap list:oneItemGeofenceList];
        });
    });

    context(@"clearing geofences", ^{

        beforeEach(^{
            registrar = [[PCFPushGeofenceRegistrar alloc] initWithLocationManager:locationManager];
        });

        it(@"should do nothing if there are no currently registered geofences", ^{
            [locationManager stub:@selector(monitoredRegions) andReturn:[NSSet set]];
            [[locationManager shouldNot] receive:@selector(stopMonitoringForRegion:)];
            [registrar reset];
        });

        it(@"should clear some geofences if there are some currently registered", ^{
            CLRegion *region1 = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(5.0, 5.0) radius:10.0 identifier:@"REGION1"];
            CLRegion *region2 = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(6.0, 6.0) radius:11.0 identifier:@"REGION2"];
            NSSet* expectedGeofences = [NSSet setWithArray:@[ region1, region2 ]];
            NSMutableSet* actualGeofences = [NSMutableSet set];
            [locationManager stub:@selector(monitoredRegions) andReturn:expectedGeofences];
            [locationManager stub:@selector(stopMonitoringForRegion:) withBlock:^id(NSArray *params) {
                [actualGeofences addObject:params[0]];
                return nil;
            }];
            [registrar reset];
            [[actualGeofences should] containObjects:region1, region2, nil];
        });
    });
});

SPEC_END