//
//  PCFPushGeofenceLocationMapSpec.m
//  PCFPushSpecs
//
//  Created by DX181-XL on 2015-04-14.
//
//

#import "Kiwi.h"
#import "PCFPushGeofenceLocation.h"
#import "PCFPushGeofenceLocationMap.h"
#import "NSObject+PCFJSONizable.h"
#import "PCFPushGeofenceDataList.h"
#import "PCFPushGeofenceDataList+Loaders.h"
#import "PCFPushGeofenceData.h"

SPEC_BEGIN(PCFPushGeofenceLocationMapSpec)

describe(@"PCFPushGeofenceLocation", ^{

    __block PCFPushGeofenceLocationMap *model;
    __block PCFPushGeofenceDataList *oneItemGeofenceList;

    __block PCFPushGeofenceDataList* (^loadGeofenceList)(NSString *name) = ^PCFPushGeofenceDataList *(NSString *name) {
        NSString *filePath = [[NSBundle bundleForClass:[self class]] pathForResource:name ofType:@"json"];
        NSData *data = [NSData dataWithContentsOfFile:filePath];
        [[data shouldNot] beNil];
        PCFPushGeofenceDataList *result = [PCFPushGeofenceDataList listFromData:data];
        return result;
    };

    beforeEach(^{
        oneItemGeofenceList = loadGeofenceList(@"geofence_one_item");
        model = [PCFPushGeofenceLocationMap map];
    });

    it(@"should be initializable", ^{
        [[model shouldNot] beNil];
    });

    it(@"should start as empty", ^{
        [[model should] haveCountOf:0];
    });

    it(@"should let you put things in the map with a location" ,^{
        PCFPushGeofenceData *geofence = oneItemGeofenceList[@7L];
        PCFPushGeofenceLocation *location = geofence.locations[0];
        [model put:geofence location:location];
        [[model should] haveCountOf:1];
        [[model[@"PCF_7_66"] should] equal:location];
    });

    it(@"should let you put things in the map with a location index" ,^{
        PCFPushGeofenceData *geofence = oneItemGeofenceList[@7L];
        [model put:geofence locationIndex:0];
        [[model should] haveCountOf:1];
        [[model[@"PCF_7_66"] should] equal:geofence.locations[0]];
    });


});

SPEC_END
