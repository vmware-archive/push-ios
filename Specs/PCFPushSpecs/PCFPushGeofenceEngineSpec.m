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
#import "PCFPushGeofenceResponseData+Loaders.h"
#import "PCFPushGeofenceData.h"

SPEC_BEGIN(PCFPushGeofenceEngineSpec)

    describe(@"PCFPushGeofenceEngine", ^{

        __block PCFPushGeofenceEngine *engine;
        __block PCFPushGeofenceRegistrar *registrar;
        __block PCFPushGeofencePersistentStore *store;
        __block PCFPushGeofenceResponseData *emptyResponseData;
        __block PCFPushGeofenceResponseData *oneItemResponseData;
        __block PCFPushGeofenceResponseData *complexResponseData;
        __block PCFPushGeofenceResponseData *oneOtherItemResponseData;
        __block PCFPushGeofenceResponseData *insufficientDataResponseData;
        __block PCFPushGeofenceDataList *emptyGeofenceList;
        __block PCFPushGeofenceDataList *oneItemGeofenceList;
        __block PCFPushGeofenceDataList *threeItemGeofenceList;
        __block PCFPushGeofenceDataList *fiveItemGeofenceList;
        __block PCFPushGeofenceDataList *expectedGeofencesToStore;
        __block PCFPushGeofenceLocationMap *expectedGeofencesToRegister;

        beforeEach(^{
            emptyResponseData = loadResponseData([self class], @"geofence_response_data_empty");
            oneItemResponseData = loadResponseData([self class], @"geofence_response_data_one_item");
            complexResponseData = loadResponseData([self class], @"geofence_response_data_complex");
            oneOtherItemResponseData = loadResponseData([self class], @"geofence_response_data_one_other_item");
            insufficientDataResponseData = loadResponseData([self class], @"geofence_response_data_all_items_culled");
            oneItemGeofenceList = loadGeofenceList([self class], @"geofence_one_item");
            threeItemGeofenceList = loadGeofenceList([self class], @"geofence_three_items");
            fiveItemGeofenceList = loadGeofenceList([self class], @"geofence_five_items");
            emptyGeofenceList = [PCFPushGeofenceDataList list];
            expectedGeofencesToRegister = [PCFPushGeofenceLocationMap map];
            expectedGeofencesToStore = [PCFPushGeofenceDataList list];
            [NSDate stub:@selector(date) andReturn:[NSDate dateWithTimeIntervalSince1970:0]]; // Pretend the time is always zero so that nothing is expired.
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
                [[registrar shouldNot] receive:@selector(registerGeofences:list:)];
                [[registrar should] receive:@selector(reset) withCount:1];
                [[store shouldNot] receive:@selector(saveRegisteredGeofences:)];
                [[store should] receive:@selector(reset) withCount:1];
                [engine processResponseData:nil withTimestamp:0L];
            });

            it(@"should do nothing if passed a null response data with some timestamp", ^{
                [[registrar shouldNot] receive:@selector(registerGeofences:list:)];
                [[registrar shouldNot] receive:@selector(reset)];
                [[store shouldNot] receive:@selector(saveRegisteredGeofences:)];
                [[store shouldNot] receive:@selector(reset)];
                [engine processResponseData:nil withTimestamp:50L];
            });

            it(@"should do a reset if passed empty response data with no timestamp", ^{
                [[registrar shouldNot] receive:@selector(registerGeofences:list:)];
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
                [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                [engine processResponseData:emptyResponseData withTimestamp:50L];
            });

            it(@"should register one item if there are no currently registered geofences and an update provides one (with no timestamp)", ^{
                [expectedGeofencesToRegister put:oneItemResponseData.geofences[0] locationIndex:0];
                expectedGeofencesToStore[@9L] = oneItemResponseData.geofences[0];
                [[store should] receive:@selector(reset)];
                [[registrar should] receive:@selector(reset)];
                [[store shouldNot] receive:@selector(currentlyRegisteredGeofences)];
                [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                [engine processResponseData:oneItemResponseData withTimestamp:0L];
            });

            it(@"should register one item if there are no currently registered geofences and an update provides one (with a timestamp)", ^{
                [expectedGeofencesToRegister put:oneItemResponseData.geofences[0] locationIndex:0]; // item with ID 9
                expectedGeofencesToStore[@9L] = oneItemResponseData.geofences[0]; // item with ID 9
                [[store shouldNot] receive:@selector(reset)];
                [[registrar shouldNot] receive:@selector(reset)];
                [[store should] receive:@selector(currentlyRegisteredGeofences) andReturn:emptyGeofenceList];
                [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                [engine processResponseData:oneItemResponseData withTimestamp:50L];
            });

            it(@"should reregister the same geofence if passed an update to a currently registered geofence (with no timestamp)", ^{
                [expectedGeofencesToRegister put:oneOtherItemResponseData.geofences[0] locationIndex:0]; // item with ID 7
                expectedGeofencesToStore[@7L] = oneOtherItemResponseData.geofences[0]; // item with ID 7
                [[store should] receive:@selector(reset)];
                [[registrar should] receive:@selector(reset)];
                [[store shouldNot] receive:@selector(currentlyRegisteredGeofences)];
                [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                [engine processResponseData:oneOtherItemResponseData withTimestamp:0L];
            });

            it(@"should reregister the same geofence if passed an update to a currently registered geofence (with some timestamp)", ^{
                [expectedGeofencesToRegister put:oneOtherItemResponseData.geofences[0] locationIndex:0]; // item with ID 7
                expectedGeofencesToStore[@7L] = oneOtherItemResponseData.geofences[0]; // item with ID 7
                [[store shouldNot] receive:@selector(reset)];
                [[registrar shouldNot] receive:@selector(reset)];
                [[store should] receive:@selector(currentlyRegisteredGeofences) andReturn:oneItemGeofenceList];
                [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                [engine processResponseData:oneOtherItemResponseData withTimestamp:50L];
            });

            it(@"should register one item that is not currently registered when one other item is already saved (with no timestamp)", ^{
                [expectedGeofencesToRegister put:oneItemResponseData.geofences[0] locationIndex:0]; // item with ID 9
                expectedGeofencesToStore[@9L] = oneItemResponseData.geofences[0]; // item with ID 9
                [[store should] receive:@selector(reset)];
                [[registrar should] receive:@selector(reset)];
                [[store shouldNot] receive:@selector(currentlyRegisteredGeofences)];
                [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                [engine processResponseData:oneItemResponseData withTimestamp:0L];
            });

            it(@"should register one item that is not currently registered when one other item is already saved (with some timestamp)", ^{
                [expectedGeofencesToRegister put:oneItemGeofenceList[@7L] locationIndex:0]; // item with ID 7
                [expectedGeofencesToRegister put:oneItemResponseData.geofences[0] locationIndex:0]; // item with ID 9
                expectedGeofencesToStore[@7L] = oneItemGeofenceList[@7L]; // item with ID 7
                expectedGeofencesToStore[@9L] = oneItemResponseData.geofences[0]; // item with ID 9
                [[store shouldNot] receive:@selector(reset)];
                [[registrar shouldNot] receive:@selector(reset)];
                [[store should] receive:@selector(currentlyRegisteredGeofences) andReturn:oneItemGeofenceList];
                [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                [engine processResponseData:oneItemResponseData withTimestamp:50L];
            });

            it(@"should let you updates some items when there's no timestamp", ^{
                [expectedGeofencesToRegister put:complexResponseData.geofences[0] locationIndex:0]; // ID 5  -- was added
                [expectedGeofencesToRegister put:complexResponseData.geofences[1] locationIndex:0]; // ID 10  -- was added
                [expectedGeofencesToRegister put:complexResponseData.geofences[2] locationIndex:0]; // ID 44  -- was added (1st location)
                [expectedGeofencesToRegister put:complexResponseData.geofences[2] locationIndex:1]; // ID 44  -- was added (2nd location)
                [expectedGeofencesToRegister put:complexResponseData.geofences[2] locationIndex:2]; // ID 44  -- was added (3rd location)
                expectedGeofencesToStore[@5] = complexResponseData.geofences[0]; // ID 5 - was added
                expectedGeofencesToStore[@10] = complexResponseData.geofences[1]; // ID 10 was added
                expectedGeofencesToStore[@44] = complexResponseData.geofences[2]; // ID 44 was added (with three locations)
                [[store should] receive:@selector(reset)];
                [[registrar should] receive:@selector(reset)];
                [[store shouldNot] receive:@selector(currentlyRegisteredGeofences)];
                [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                [engine processResponseData:complexResponseData withTimestamp:0L];
            });

            context(@"updates with a timestamp", ^{

                it(@"update some items, no items currently stored", ^{
                    [expectedGeofencesToRegister put:complexResponseData.geofences[0] locationIndex:0]; // ID 5  -- was added
                    [expectedGeofencesToRegister put:complexResponseData.geofences[1] locationIndex:0]; // ID 10  -- was added
                    [expectedGeofencesToRegister put:complexResponseData.geofences[2] locationIndex:0]; // ID 44  -- was added (1st location)
                    [expectedGeofencesToRegister put:complexResponseData.geofences[2] locationIndex:1]; // ID 44  -- was added (2nd location)
                    [expectedGeofencesToRegister put:complexResponseData.geofences[2] locationIndex:2]; // ID 44  -- was added (3rd location)
                    expectedGeofencesToStore[@5] = complexResponseData.geofences[0]; // ID 5 was adde
                    expectedGeofencesToStore[@10] = complexResponseData.geofences[1]; // ID 10 was added
                    expectedGeofencesToStore[@44] = complexResponseData.geofences[2]; // ID 44 was added (with three locations)
                    [[store shouldNot] receive:@selector(reset)];
                    [[registrar shouldNot] receive:@selector(reset)];
                    [[store should] receive:@selector(currentlyRegisteredGeofences) andReturn:emptyGeofenceList];
                    [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                    [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                    [engine processResponseData:complexResponseData withTimestamp:50L];
                });

                it(@"update some items, one item currently stored", ^{
                    [expectedGeofencesToRegister put:complexResponseData.geofences[0] locationIndex:0]; // ID 5  -- was added
                    [expectedGeofencesToRegister put:complexResponseData.geofences[1] locationIndex:0]; // ID 10  -- was added
                    [expectedGeofencesToRegister put:complexResponseData.geofences[2] locationIndex:0]; // ID 44  -- was added (1st location)
                    [expectedGeofencesToRegister put:complexResponseData.geofences[2] locationIndex:1]; // ID 44  -- was added (2nd location)
                    [expectedGeofencesToRegister put:complexResponseData.geofences[2] locationIndex:2]; // ID 44  -- was added (3rd location)
                    [expectedGeofencesToRegister put:oneItemGeofenceList[@7L] locationIndex:0]; // ID 7 -- was kept
                    expectedGeofencesToStore[@5] = complexResponseData.geofences[0]; // ID 5 was added
                    expectedGeofencesToStore[@10] = complexResponseData.geofences[1]; // ID 10 was added
                    expectedGeofencesToStore[@44] = complexResponseData.geofences[2]; // ID 44 was added (with three locations)
                    expectedGeofencesToStore[@7] = oneItemGeofenceList[@7L]; // ID 7 was kept
                    [[store shouldNot] receive:@selector(reset)];
                    [[registrar shouldNot] receive:@selector(reset)];
                    [[store should] receive:@selector(currentlyRegisteredGeofences) andReturn:oneItemGeofenceList];
                    [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                    [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                    [engine processResponseData:complexResponseData withTimestamp:50L];
                });

                it(@"update some items, many items currently stored", ^{
                    [expectedGeofencesToRegister put:complexResponseData.geofences[0] locationIndex:0]; // ID 5  -- was added
                    [expectedGeofencesToRegister put:complexResponseData.geofences[1] locationIndex:0]; // ID 10  -- was added
                    [expectedGeofencesToRegister put:complexResponseData.geofences[2] locationIndex:0]; // ID 44  -- was added (1st location)
                    [expectedGeofencesToRegister put:complexResponseData.geofences[2] locationIndex:1]; // ID 44  -- was added (2nd location)
                    [expectedGeofencesToRegister put:complexResponseData.geofences[2] locationIndex:2]; // ID 44  -- was added (3rd location)
                    [expectedGeofencesToRegister put:threeItemGeofenceList[@7L] locationIndex:0]; // ID 7 -- was kept. Note: ID 9 was deleted.
                    expectedGeofencesToStore[@5] = complexResponseData.geofences[0]; // ID 5 was added
                    expectedGeofencesToStore[@10] = complexResponseData.geofences[1]; // ID 10 was added
                    expectedGeofencesToStore[@44] = complexResponseData.geofences[2]; // ID 44 was added (with three locations)
                    expectedGeofencesToStore[@7] = threeItemGeofenceList[@7L]; // ID 7 was kept. Note: ID 9 was deleted.
                    [[store shouldNot] receive:@selector(reset)];
                    [[registrar shouldNot] receive:@selector(reset)];
                    [[store should] receive:@selector(currentlyRegisteredGeofences) andReturn:threeItemGeofenceList];
                    [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                    [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                    [engine processResponseData:complexResponseData withTimestamp:50L];
                });
            });

            context(@"filtering items with invalid data", ^{

                it(@"should filter items with insufficient data", ^{
                    [[store shouldNot] receive:@selector(reset)];
                    [[registrar shouldNot] receive:@selector(reset)];
                    [[store should] receive:@selector(currentlyRegisteredGeofences) andReturn:emptyGeofenceList];
                    [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                    [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                    [engine processResponseData:insufficientDataResponseData withTimestamp:50L];
                });
            });

            context(@"filter expired items", ^{

                beforeEach(^{
                    NSDate *fakeDate = [NSDate dateWithTimeIntervalSince1970:991142744.274]; // Tue May 29 2001
                    [NSDate stub:@selector(date) andReturn:fakeDate];
                    [[store shouldNot] receive:@selector(reset)];
                    [[registrar shouldNot] receive:@selector(reset)];
                });

                it(@"should filter expired items from store", ^{
                    [expectedGeofencesToRegister put:threeItemGeofenceList[@7L] locationIndex:0]; // IDs 7 and 44 were registered.  Note that ID 9 has expired.
                    [expectedGeofencesToRegister put:threeItemGeofenceList[@44L] locationIndex:0];
                    [expectedGeofencesToRegister put:threeItemGeofenceList[@44L] locationIndex:1];
                    expectedGeofencesToStore[@7L] = threeItemGeofenceList[@7L];
                    expectedGeofencesToStore[@44L] = threeItemGeofenceList[@44L];
                    [[store should] receive:@selector(currentlyRegisteredGeofences) andReturn:threeItemGeofenceList];
                    [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                    [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                    [engine processResponseData:emptyResponseData withTimestamp:50L];
                });

                it(@"should filter expired items from updates", ^{
                    [expectedGeofencesToRegister put:complexResponseData.geofences[0] locationIndex:0];
                    expectedGeofencesToStore[@5L] = complexResponseData.geofences[0];
                    [[store should] receive:@selector(currentlyRegisteredGeofences) andReturn:emptyGeofenceList];
                    [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                    [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                    [engine processResponseData:complexResponseData withTimestamp:50L];
                });

                it(@"should filter expired items that are not expired but receive updates that are expired", ^{
                    [expectedGeofencesToRegister put:threeItemGeofenceList[@7L] locationIndex:0]; // Note that item ID 44 becomes expired in the update
                    [expectedGeofencesToRegister put:complexResponseData.geofences[0] locationIndex:0];
                    expectedGeofencesToStore[@7L] = threeItemGeofenceList[@7L];
                    expectedGeofencesToStore[@5L] = complexResponseData.geofences[0];
                    [[store should] receive:@selector(currentlyRegisteredGeofences) andReturn:threeItemGeofenceList];
                    [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                    [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                    [engine processResponseData:complexResponseData withTimestamp:50L];
                });

                it(@"should retain stored expired items that receive updates that are not expired", ^{
                    [expectedGeofencesToRegister put:fiveItemGeofenceList[@11L] locationIndex:0]; // Note that item ID 11 is kept from the store (including the 'old' version of item ID 5)
                    [expectedGeofencesToRegister put:complexResponseData.geofences[0] locationIndex:0]; // Note that item ID 5 is the only unexpired item in the update data
                    expectedGeofencesToStore[@11L] = fiveItemGeofenceList[@11L];
                    expectedGeofencesToStore[@5L] = complexResponseData.geofences[0];
                    [[store should] receive:@selector(currentlyRegisteredGeofences) andReturn:fiveItemGeofenceList];
                    [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                    [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                    [engine processResponseData:complexResponseData withTimestamp:50L];
                });
            });
        });

        context(@"clearing items", ^{

            it(@"should do nothing if you try to clear a null list", ^{
                [[store shouldNot] receive:@selector(currentlyRegisteredGeofences)];
                [[store shouldNot] receive:@selector(saveRegisteredGeofences:)];
                [[registrar shouldNot] receive:@selector(registerGeofences:list:)];
                [[registrar shouldNot] receive:@selector(unregisterGeofences:geofencesToKeep:list:)];
                [engine clearLocations:nil];
            });

            it(@"should do nothing if you try to clear an empty list", ^{
                [[store shouldNot] receive:@selector(currentlyRegisteredGeofences)];
                [[store shouldNot] receive:@selector(saveRegisteredGeofences:)];
                [[registrar shouldNot] receive:@selector(registerGeofences:list:)];
                [[registrar shouldNot] receive:@selector(unregisterGeofences:geofencesToKeep:list:)];
                [engine clearLocations:[PCFPushGeofenceLocationMap map]];
            });

            it(@"should be able to clear one item", ^{
               [store stub:@selector(currentlyRegisteredGeofences) andReturn:fiveItemGeofenceList];

                PCFPushGeofenceLocationMap *oneItemMapToClear = [PCFPushGeofenceLocationMap map];
                [oneItemMapToClear put:fiveItemGeofenceList[@11L] locationIndex:0];

                expectedGeofencesToStore[@5L] = fiveItemGeofenceList[@5L];
                expectedGeofencesToStore[@44L] = fiveItemGeofenceList[@44L];
                expectedGeofencesToStore[@49L] = fiveItemGeofenceList[@49L];
                expectedGeofencesToStore[@51L] = fiveItemGeofenceList[@51L];

                expectedGeofencesToRegister = [PCFPushGeofenceLocationMap mapWithGeofencesInList:expectedGeofencesToStore];

                [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                [[registrar shouldNot] receive:@selector(registerGeofences:list:)];
                [[registrar should] receive:@selector(unregisterGeofences:geofencesToKeep:list:) withArguments:oneItemMapToClear, expectedGeofencesToRegister, fiveItemGeofenceList, nil];

                [engine clearLocations:oneItemMapToClear];
            });

            it(@"should be able to clear two items", ^{
                [store stub:@selector(currentlyRegisteredGeofences) andReturn:fiveItemGeofenceList];

                PCFPushGeofenceLocationMap *twoItemMapToClear = [PCFPushGeofenceLocationMap map];
                [twoItemMapToClear put:fiveItemGeofenceList[@11L] locationIndex:0];
                [twoItemMapToClear put:fiveItemGeofenceList[@44L] locationIndex:0];

                PCFPushGeofenceData *item44 = [fiveItemGeofenceList[@44L] newCopyWithoutLocations];
                item44.locations = @[ ((PCFPushGeofenceData *)(fiveItemGeofenceList[@44L])).locations[1] ];
                expectedGeofencesToStore[@5L] = fiveItemGeofenceList[@5L];
                expectedGeofencesToStore[@44L] = item44;
                expectedGeofencesToStore[@49L] = fiveItemGeofenceList[@49L];
                expectedGeofencesToStore[@51L] = fiveItemGeofenceList[@51L];

                expectedGeofencesToRegister = [PCFPushGeofenceLocationMap mapWithGeofencesInList:expectedGeofencesToStore];

                [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                [[registrar shouldNot] receive:@selector(registerGeofences:list:)];
                [[registrar should] receive:@selector(unregisterGeofences:geofencesToKeep:list:) withArguments:twoItemMapToClear, expectedGeofencesToRegister, fiveItemGeofenceList, nil];

                [engine clearLocations:twoItemMapToClear];
            });

            it(@"should be able to clear six items", ^{
                [store stub:@selector(currentlyRegisteredGeofences) andReturn:fiveItemGeofenceList];

                PCFPushGeofenceLocationMap *sixItemMapToClear = [PCFPushGeofenceLocationMap map];
                [sixItemMapToClear put:fiveItemGeofenceList[@5L] locationIndex:0];
                [sixItemMapToClear put:fiveItemGeofenceList[@11L] locationIndex:0];
                [sixItemMapToClear put:fiveItemGeofenceList[@44L] locationIndex:0];
                [sixItemMapToClear put:fiveItemGeofenceList[@44L] locationIndex:1];
                [sixItemMapToClear put:fiveItemGeofenceList[@49L] locationIndex:1];
                [sixItemMapToClear put:fiveItemGeofenceList[@51L] locationIndex:0];

                PCFPushGeofenceData *item49 = [fiveItemGeofenceList[@49L] newCopyWithoutLocations];
                item49.locations = @[ ((PCFPushGeofenceData *)(fiveItemGeofenceList[@49L])).locations[0] ];
                expectedGeofencesToStore[@49L] = item49;

                expectedGeofencesToRegister = [PCFPushGeofenceLocationMap mapWithGeofencesInList:expectedGeofencesToStore];

                [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                [[registrar shouldNot] receive:@selector(registerGeofences:list:)];
                [[registrar should] receive:@selector(unregisterGeofences:geofencesToKeep:list:) withArguments:sixItemMapToClear, expectedGeofencesToRegister, fiveItemGeofenceList, nil];

                [engine clearLocations:sixItemMapToClear];
            });

            it(@"should be able to clear when some items do not exist", ^{
                [store stub:@selector(currentlyRegisteredGeofences) andReturn:fiveItemGeofenceList];

                PCFPushGeofenceLocationMap *twoItemMapToClear = [PCFPushGeofenceLocationMap map];
                [twoItemMapToClear put:threeItemGeofenceList[@7L] locationIndex:0];
                [twoItemMapToClear put:threeItemGeofenceList[@9L] locationIndex:0];

                expectedGeofencesToStore[@5L] = fiveItemGeofenceList[@5L];
                expectedGeofencesToStore[@11L] = fiveItemGeofenceList[@11L];
                expectedGeofencesToStore[@44L] = fiveItemGeofenceList[@44L];
                expectedGeofencesToStore[@49L] = fiveItemGeofenceList[@49L];
                expectedGeofencesToStore[@51L] = fiveItemGeofenceList[@51L];

                expectedGeofencesToRegister = [PCFPushGeofenceLocationMap mapWithGeofencesInList:expectedGeofencesToStore];

                [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                [[registrar shouldNot] receive:@selector(registerGeofences:list:)];
                [[registrar should] receive:@selector(unregisterGeofences:geofencesToKeep:list:) withArguments:twoItemMapToClear, expectedGeofencesToRegister, fiveItemGeofenceList, nil];

                [engine clearLocations:twoItemMapToClear];
            });
        });
    });

SPEC_END