//
// Created by DX181-XL on 15-04-15.
//

#import "Kiwi.h"
#import "PCFPushGeofenceEngine.h"
#import "PCFPushGeofenceRegistrar.h"
#import "PCFPushGeofencePersistentStore.h"
#import "PCFPushGeofenceResponseData.h"
#import "PCFPushGeofenceDataList.h"
#import "PCFPushGeofenceDataList+Loaders.h"
#import "PCFPushGeofenceLocationMap.h"
#import "NSObject+PCFJSONizable.h"

SPEC_BEGIN(PCFPushGeofenceEngineSpec)

    describe(@"PCFPushGeofenceEngine", ^{

        __block PCFPushGeofenceEngine *engine;
        __block PCFPushGeofenceRegistrar *registrar;
        __block PCFPushGeofencePersistentStore *store;

        __block PCFPushGeofenceResponseData *emptyResponseData;
        __block PCFPushGeofenceResponseData *oneItemResponseData;
        __block PCFPushGeofenceDataList *emptyGeofenceList;
        __block PCFPushGeofenceDataList *oneItemGeofenceList;
        __block PCFPushGeofenceLocationMap *expectedGeofencesToRegister;
        __block PCFPushGeofenceDataList *expectedGeofencesToStore;

        __block PCFPushGeofenceDataList* (^loadGeofenceList)(NSString *name) = ^PCFPushGeofenceDataList *(NSString *name) {
            NSString *filePath = [[NSBundle bundleForClass:[self class]] pathForResource:name ofType:@"json"];
            NSData *data = [NSData dataWithContentsOfFile:filePath];
            [[data shouldNot] beNil];
            PCFPushGeofenceDataList *result = [PCFPushGeofenceDataList listFromData:data];
            return result;
        };

        __block PCFPushGeofenceResponseData* (^loadResponseData)(NSString *name) = ^PCFPushGeofenceResponseData *(NSString *name) {
            NSError *error;
            NSString *filePath = [[NSBundle bundleForClass:[self class]] pathForResource:name ofType:@"json"];
            NSData *data = [NSData dataWithContentsOfFile:filePath];
            [[data shouldNot] beNil];
            PCFPushGeofenceResponseData *result = [PCFPushGeofenceResponseData pcf_fromJSONData:data error:&error];
            [[error should] beNil];
            return result;
        };

        beforeEach(^{
            emptyResponseData = loadResponseData(@"geofence_response_data_empty");
            oneItemResponseData = loadResponseData(@"geofence_response_data_one_item");
            oneItemGeofenceList = loadGeofenceList(@"geofence_one_item");
            emptyGeofenceList = [[PCFPushGeofenceDataList alloc] init];
            expectedGeofencesToRegister = [[PCFPushGeofenceLocationMap alloc] init];
            expectedGeofencesToStore = [[PCFPushGeofenceDataList alloc] init];
        });

        afterEach(^{
            engine = nil;
        });

        context(@"check dependencies", ^{

            it(@"should require a geofence registrar", ^{

                [[theBlock(^{
                    [[PCFPushGeofenceEngine alloc] initWithRegistrar:nil store:store];
                }) should] raiseWithName:NSInvalidArgumentException];

            });

            it(@"should require a geofence persistent store", ^{
                [[theBlock(^{
                    [[PCFPushGeofenceEngine alloc] initWithRegistrar:registrar store:nil];
                }) should] raiseWithName:NSInvalidArgumentException];

            });
        });

        context(@"processing response data", ^{

            beforeEach(^{
                registrar = [PCFPushGeofenceRegistrar mock];
                store = [PCFPushGeofencePersistentStore mock];
                engine = [[PCFPushGeofenceEngine alloc] initWithRegistrar:registrar store:store];
            });

            it(@"should do a reset if passed a null response data with no (or zero) timestamp", ^{
                [[registrar shouldNot] receive:@selector(registerGeofences:geofenceDataList:)];
                [[registrar should] receive:@selector(reset) withCount:1];
                [[store shouldNot] receive:@selector(saveRegisteredGeofences:)];
                [[store should] receive:@selector(reset) withCount:1];
                [engine processResponseData:nil withTimestamp:0L];
            });

            it(@"should do nothing if passed a null response data with some timestamp", ^{
                [[registrar shouldNot] receive:@selector(registerGeofences:geofenceDataList:)];
                [[registrar shouldNot] receive:@selector(reset)];
                [[store shouldNot] receive:@selector(saveRegisteredGeofences:)];
                [[store shouldNot] receive:@selector(reset)];
                [engine processResponseData:nil withTimestamp:50L];
            });

            it(@"should do a reset if passed empty response data with no timestamp", ^{
                [[registrar shouldNot] receive:@selector(registerGeofences:geofenceDataList:)];
                [[registrar should] receive:@selector(reset) withCount:1];
                [[store shouldNot] receive:@selector(saveRegisteredGeofences:)];
                [[store should] receive:@selector(reset) withCount:1];
                [engine processResponseData:emptyResponseData withTimestamp:0L];
            });

            it(@"should reregister the same geofence if passed empty response data with some timestamp and one geofence is already registered", ^{
                [expectedGeofencesToRegister put:oneItemGeofenceList[@7L] locationIndex:0];
                expectedGeofencesToStore[@7L] = oneItemGeofenceList[@7L];
                [[store shouldNot] receive:@selector(reset)];
                [[store should] receive:@selector(currentlyRegisteredGeofences) andReturn:oneItemGeofenceList];
                [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:oneItemGeofenceList, nil];
                [[registrar shouldNot] receive:@selector(reset)];
                [[registrar should] receive:@selector(registerGeofences:geofenceDataList:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                [engine processResponseData:emptyResponseData withTimestamp:50L];
            });

            it(@"should register one item if there are no currently registered geofences and an update provides one (with no timestamp)", ^{
                [expectedGeofencesToRegister put:oneItemResponseData.geofences[0] locationIndex:0];
                expectedGeofencesToStore[@9L] = oneItemResponseData.geofences[0];
                [[store should] receive:@selector(reset)];
                [[registrar should] receive:@selector(reset)];
                [[store shouldNot] receive:@selector(currentlyRegisteredGeofences)];
                [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                [[registrar should] receive:@selector(registerGeofences:geofenceDataList:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                [engine processResponseData:oneItemResponseData withTimestamp:0L];
            });

            it(@"should register one item if there are no currently registered geofences and an update provides one (with a timestamp)", ^{
                [expectedGeofencesToRegister put:oneItemResponseData.geofences[0] locationIndex:0];
                expectedGeofencesToStore[@9L] = oneItemResponseData.geofences[0];
                [[store shouldNot] receive:@selector(reset)];
                [[registrar shouldNot] receive:@selector(reset)];
                [[store should] receive:@selector(currentlyRegisteredGeofences) andReturn:emptyGeofenceList];
                [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                [[registrar should] receive:@selector(registerGeofences:geofenceDataList:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                [engine processResponseData:oneItemResponseData withTimestamp:50L];
            });
        });

    });

SPEC_END