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
        __block PCFPushGeofenceResponseData *oneItemBadTriggerResponseData;
        __block PCFPushGeofenceResponseData *oneDeletedItemResponseData;
        __block PCFPushGeofenceResponseData *oneOtherDeletedItemResponseData;
        __block PCFPushGeofenceResponseData *oneItemWithTagResponseData;
        __block PCFPushGeofenceResponseData *oneOtherItemWithNoTagResponseData;
        __block PCFPushGeofenceResponseData *oneOtherItemWithTagResponseData;
        __block PCFPushGeofenceDataList *emptyGeofenceList;
        __block PCFPushGeofenceDataList *oneItemGeofenceList;
        __block PCFPushGeofenceDataList *oneItemWithTagGeofenceList;
        __block PCFPushGeofenceDataList *threeItemGeofenceList;
        __block PCFPushGeofenceDataList *threeItemWithTagsGeofenceList;
        __block PCFPushGeofenceDataList *fiveItemGeofenceList;
        __block PCFPushGeofenceDataList *oneItemBadRadiusGeofenceList;
        __block PCFPushGeofenceDataList *expectedGeofencesToStore;
        __block PCFPushGeofenceLocationMap *expectedGeofencesToRegister;
        __block NSSet *emptySubscribedTags;

        beforeEach(^{
            emptyResponseData = loadResponseData([self class], @"geofence_response_data_empty");
            oneItemResponseData = loadResponseData([self class], @"geofence_response_data_one_item");
            complexResponseData = loadResponseData([self class], @"geofence_response_data_complex");
            oneOtherItemResponseData = loadResponseData([self class], @"geofence_response_data_one_other_item");
            insufficientDataResponseData = loadResponseData([self class], @"geofence_response_data_all_items_culled");
            oneItemBadTriggerResponseData = loadResponseData([self class], @"geofence_response_data_one_item_bad_trigger");
            oneDeletedItemResponseData = loadResponseData([self class], @"geofence_response_data_delete_one");
            oneOtherDeletedItemResponseData = loadResponseData([self class], @"geofence_response_data_delete_one_other");
            oneItemWithTagResponseData = loadResponseData([self class], @"geofence_response_data_one_item_with_tag");
            oneOtherItemWithNoTagResponseData = loadResponseData([self class], @"geofence_response_data_one_other_item_with_no_tag");
            oneOtherItemWithTagResponseData = loadResponseData([self class], @"geofence_response_data_one_other_item_with_tag");
            oneItemGeofenceList = loadGeofenceList([self class], @"geofence_one_item");
            oneItemWithTagGeofenceList = loadGeofenceList([self class], @"geofence_one_item_with_tag");
            threeItemGeofenceList = loadGeofenceList([self class], @"geofence_three_items");
            threeItemWithTagsGeofenceList = loadGeofenceList([self class], @"geofence_three_items_with_tag");
            fiveItemGeofenceList = loadGeofenceList([self class], @"geofence_five_items");
            oneItemBadRadiusGeofenceList = loadGeofenceList([self class], @"geofence_one_item_bad_radius");
            emptyGeofenceList = [PCFPushGeofenceDataList list];
            expectedGeofencesToRegister = [PCFPushGeofenceLocationMap map];
            expectedGeofencesToStore = [PCFPushGeofenceDataList list];
            emptySubscribedTags = [NSSet set];
            [NSDate stub:@selector(date) andReturn:[NSDate dateWithTimeIntervalSince1970:0]]; // Pretend the time is always zero so that nothing is expired.
        });

        context(@"check dependencies", ^{

            it(@"should require a geofence registrar", ^{

                [[theBlock(^{
                    engine = [[PCFPushGeofenceEngine alloc] initWithRegistrar:nil store:store];
                }) should] raiseWithName:NSInvalidArgumentException];

            });

            it(@"should require a geofence persistent store", ^{
                [[theBlock(^{
                    engine = [[PCFPushGeofenceEngine alloc] initWithRegistrar:registrar store:nil];
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
                [engine processResponseData:nil withTimestamp:0L withTags:nil];
            });

            it(@"should do nothing if passed a null response data with some timestamp", ^{
                [[registrar shouldNot] receive:@selector(registerGeofences:list:)];
                [[registrar shouldNot] receive:@selector(reset)];
                [[store shouldNot] receive:@selector(saveRegisteredGeofences:)];
                [[store shouldNot] receive:@selector(reset)];
                [engine processResponseData:nil withTimestamp:50L withTags:nil];
            });

            it(@"should do a reset if passed empty response data with no timestamp", ^{
                [[registrar shouldNot] receive:@selector(registerGeofences:list:)];
                [[registrar should] receive:@selector(reset) withCount:1];
                [[store shouldNot] receive:@selector(saveRegisteredGeofences:)];
                [[store should] receive:@selector(reset) withCount:1];
                [engine processResponseData:emptyResponseData withTimestamp:0L withTags:nil];
            });

            it(@"should reregister the same geofence if passed empty response data with some timestamp and one geofence is already registered", ^{
                [expectedGeofencesToRegister put:oneItemGeofenceList[@7L] locationIndex:0];
                expectedGeofencesToStore[@7L] = oneItemGeofenceList[@7L];
                [[store shouldNot] receive:@selector(reset)];
                [[store should] receive:@selector(currentlyRegisteredGeofences) andReturn:oneItemGeofenceList];
                [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:oneItemGeofenceList, nil];
                [[registrar shouldNot] receive:@selector(reset)];
                [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                [engine processResponseData:emptyResponseData withTimestamp:50L withTags:nil];
            });

            it(@"should register one item if there are no currently registered geofences and an update provides one (with no timestamp)", ^{
                [expectedGeofencesToRegister put:oneItemResponseData.geofences[0] locationIndex:0];
                expectedGeofencesToStore[@9L] = oneItemResponseData.geofences[0];
                [[store should] receive:@selector(reset)];
                [[registrar should] receive:@selector(reset)];
                [[store shouldNot] receive:@selector(currentlyRegisteredGeofences)];
                [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                [engine processResponseData:oneItemResponseData withTimestamp:0L withTags:nil];
            });

            it(@"should register one item if there are no currently registered geofences and an update provides one (with a timestamp)", ^{
                [expectedGeofencesToRegister put:oneItemResponseData.geofences[0] locationIndex:0]; // item with ID 9
                expectedGeofencesToStore[@9L] = oneItemResponseData.geofences[0]; // item with ID 9
                [[store shouldNot] receive:@selector(reset)];
                [[registrar shouldNot] receive:@selector(reset)];
                [[store should] receive:@selector(currentlyRegisteredGeofences) andReturn:emptyGeofenceList];
                [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                [engine processResponseData:oneItemResponseData withTimestamp:50L withTags:nil];
            });

            it(@"should reregister the same geofence if passed an update to a currently registered geofence (with no timestamp)", ^{
                [expectedGeofencesToRegister put:oneOtherItemResponseData.geofences[0] locationIndex:0]; // item with ID 7
                expectedGeofencesToStore[@7L] = oneOtherItemResponseData.geofences[0]; // item with ID 7
                [[store should] receive:@selector(reset)];
                [[registrar should] receive:@selector(reset)];
                [[store shouldNot] receive:@selector(currentlyRegisteredGeofences)];
                [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                [engine processResponseData:oneOtherItemResponseData withTimestamp:0L withTags:nil];
            });

            it(@"should reregister the same geofence if passed an update to a currently registered geofence (with some timestamp)", ^{
                [expectedGeofencesToRegister put:oneOtherItemResponseData.geofences[0] locationIndex:0]; // item with ID 7
                expectedGeofencesToStore[@7L] = oneOtherItemResponseData.geofences[0]; // item with ID 7
                [[store shouldNot] receive:@selector(reset)];
                [[registrar shouldNot] receive:@selector(reset)];
                [[store should] receive:@selector(currentlyRegisteredGeofences) andReturn:oneItemGeofenceList];
                [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                [engine processResponseData:oneOtherItemResponseData withTimestamp:50L withTags:nil];
            });

            it(@"should register one item that is not currently registered when one other item is already saved (with no timestamp)", ^{
                [expectedGeofencesToRegister put:oneItemResponseData.geofences[0] locationIndex:0]; // item with ID 9
                expectedGeofencesToStore[@9L] = oneItemResponseData.geofences[0]; // item with ID 9
                [[store should] receive:@selector(reset)];
                [[registrar should] receive:@selector(reset)];
                [[store shouldNot] receive:@selector(currentlyRegisteredGeofences)];
                [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                [engine processResponseData:oneItemResponseData withTimestamp:0L withTags:nil];
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
                [engine processResponseData:oneItemResponseData withTimestamp:50L withTags:nil];
            });

            it(@"should delete one item that exists (with no timestamp)", ^{
                [[store should] receive:@selector(reset)];
                [[registrar should] receive:@selector(reset)];
                [[store shouldNot] receive:@selector(currentlyRegisteredGeofences)];
                [[store shouldNot] receive:@selector(saveRegisteredGeofences:)];
                [[registrar shouldNot] receive:@selector(registerGeofences:list:)];
                [engine processResponseData:oneDeletedItemResponseData withTimestamp:0L withTags:nil];
            });

            it(@"should delete one item that exists (with some timestamp)", ^{
                [[store shouldNot] receive:@selector(reset)];
                [[registrar shouldNot] receive:@selector(reset)];
                [[store should] receive:@selector(currentlyRegisteredGeofences) andReturn:oneItemGeofenceList];
                [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                [engine processResponseData:oneDeletedItemResponseData withTimestamp:50L withTags:nil];
            });

            it(@"should delete one item that does not exist (with no timestamp)", ^{
                [[store should] receive:@selector(reset)];
                [[registrar should] receive:@selector(reset)];
                [[store shouldNot] receive:@selector(currentlyRegisteredGeofences)];
                [[store shouldNot] receive:@selector(saveRegisteredGeofences:)];
                [[registrar shouldNot] receive:@selector(registerGeofences:list:)];
                [engine processResponseData:oneOtherDeletedItemResponseData withTimestamp:0L withTags:nil];
            });

            it(@"should delete one item that does not exist (with a timestamp)", ^{
                [expectedGeofencesToRegister put:oneItemGeofenceList[@7L] locationIndex:0]; // item with ID 7
                expectedGeofencesToStore[@7L] = oneItemGeofenceList[@7L]; // item with ID 7
                [[store shouldNot] receive:@selector(reset)];
                [[registrar shouldNot] receive:@selector(reset)];
                [[store should] receive:@selector(currentlyRegisteredGeofences) andReturn:oneItemGeofenceList];
                [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                [engine processResponseData:oneOtherDeletedItemResponseData withTimestamp:50L withTags:nil];
            });

            it(@"should delete one item that does not exist with an empty store (with a timestamp)", ^{
                [[store shouldNot] receive:@selector(reset)];
                [[registrar shouldNot] receive:@selector(reset)];
                [[store should] receive:@selector(currentlyRegisteredGeofences) andReturn:emptyGeofenceList];
                [[store shouldNot] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                [[registrar shouldNot] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                [engine processResponseData:oneOtherDeletedItemResponseData withTimestamp:50L withTags:nil];
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
                [engine processResponseData:complexResponseData withTimestamp:0L withTags:nil];
            });

            context(@"tags (with a timestamp)", ^{

                beforeEach(^{
                    [[store shouldNot] receive:@selector(reset)];
                    [[registrar shouldNot] receive:@selector(reset)];
                });

                it(@"should register one item from the store with a subscribed tag and an empty response data", ^{
                    [expectedGeofencesToRegister put:oneItemWithTagGeofenceList[@7L] locationIndex:0];
                    expectedGeofencesToStore[@7L] = oneItemWithTagGeofenceList[@7L];
                    [[store should] receive:@selector(currentlyRegisteredGeofences) andReturn:oneItemWithTagGeofenceList];
                    [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                    [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                    [engine processResponseData:emptyResponseData withTimestamp:50L withTags:[NSSet setWithObject:@"pineapples"]];
                });

                it(@"should register one item from the store with an unsubscribed tag and an empty response data", ^{
                    expectedGeofencesToStore[@7L] = oneItemWithTagGeofenceList[@7L];
                    [[store should] receive:@selector(currentlyRegisteredGeofences) andReturn:oneItemWithTagGeofenceList];
                    [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                    [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                    [engine processResponseData:emptyResponseData withTimestamp:50L withTags:emptySubscribedTags];
                });

                it(@"update one item with a tag to an item with no tag while subscribed to no tags", ^{
                    [expectedGeofencesToRegister put:oneOtherItemWithNoTagResponseData.geofences[0] locationIndex:0];
                    expectedGeofencesToStore[@7L] = oneOtherItemWithNoTagResponseData.geofences[0];
                    [[store should] receive:@selector(currentlyRegisteredGeofences) andReturn:oneItemWithTagGeofenceList];
                    [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                    [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                    [engine processResponseData:oneOtherItemWithNoTagResponseData withTimestamp:50L withTags:emptySubscribedTags];
                });

                it(@"update one item with a tag to an item with no tag while subscribed to one tag", ^{
                    [expectedGeofencesToRegister put:oneOtherItemWithNoTagResponseData.geofences[0] locationIndex:0];
                    expectedGeofencesToStore[@7L] = oneOtherItemWithNoTagResponseData.geofences[0];
                    [[store should] receive:@selector(currentlyRegisteredGeofences) andReturn:oneItemWithTagGeofenceList];
                    [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                    [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                    [engine processResponseData:oneOtherItemWithNoTagResponseData withTimestamp:50L withTags:[NSSet setWithObject:@"pineapples"]];
                });

                it(@"update one item with tag to an item with a different tag while subscribed to no tag", ^{
                    expectedGeofencesToStore[@7L] = oneItemWithTagResponseData.geofences[0];
                    [[store should] receive:@selector(currentlyRegisteredGeofences) andReturn:oneItemWithTagGeofenceList];
                    [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                    [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                    [engine processResponseData:oneItemWithTagResponseData withTimestamp:50L withTags:emptySubscribedTags];
                });

                it(@"update one item with a tag to an item with a different tag while subscribed to the original tag", ^{
                    expectedGeofencesToStore[@7L] = oneItemWithTagResponseData.geofences[0];
                    [[store should] receive:@selector(currentlyRegisteredGeofences) andReturn:oneItemWithTagGeofenceList];
                    [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                    [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                    [engine processResponseData:oneItemWithTagResponseData withTimestamp:50L withTags:[NSSet setWithObject:@"pineapples"]];
                });

                it(@"update one item with a tag to an item with a different tag while subscribed to a new tag", ^{
                    [expectedGeofencesToRegister put:oneItemWithTagResponseData.geofences[0] locationIndex:0];
                    expectedGeofencesToStore[@7L] = oneItemWithTagResponseData.geofences[0];
                    [[store should] receive:@selector(currentlyRegisteredGeofences) andReturn:oneItemWithTagGeofenceList];
                    [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                    [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                    [engine processResponseData:oneItemWithTagResponseData withTimestamp:50L withTags:[NSSet setWithObject:@"ice cream"]];
                });

                it(@"update one item with no items currently registered with a subscribed tag", ^{
                    [expectedGeofencesToRegister put:oneItemWithTagResponseData.geofences[0] locationIndex:0];
                    expectedGeofencesToStore[@7L] = oneItemWithTagResponseData.geofences[0];
                    [[store should] receive:@selector(currentlyRegisteredGeofences) andReturn:emptyGeofenceList];
                    [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                    [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                    [engine processResponseData:oneItemWithTagResponseData withTimestamp:50L withTags:[NSSet setWithObject:@"ice cream"]];
                });

                it(@"update one item with no items currently registered with an unsubscribed tag", ^{
                    expectedGeofencesToStore[@7L] = oneItemWithTagResponseData.geofences[0];
                    [[store should] receive:@selector(currentlyRegisteredGeofences) andReturn:emptyGeofenceList];
                    [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                    [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                    [engine processResponseData:oneItemWithTagResponseData withTimestamp:50L withTags:emptySubscribedTags];
                });

                it(@"update one item with no tag to an item with a tag while subscribed to no tags", ^{
                    expectedGeofencesToStore[@7L] = oneOtherItemWithTagResponseData.geofences[0];
                    [[store should] receive:@selector(currentlyRegisteredGeofences) andReturn:oneItemGeofenceList];
                    [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                    [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                    [engine processResponseData:oneOtherItemWithTagResponseData withTimestamp:50L withTags:emptySubscribedTags];
                });

                it(@"update one item with no tag to an item with a tag while subscribed to that tag", ^{
                    [expectedGeofencesToRegister put:oneOtherItemWithTagResponseData.geofences[0] locationIndex:0];
                    expectedGeofencesToStore[@7L] = oneOtherItemWithTagResponseData.geofences[0];
                    [[store should] receive:@selector(currentlyRegisteredGeofences) andReturn:oneItemGeofenceList];
                    [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                    [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                    [engine processResponseData:oneOtherItemWithTagResponseData withTimestamp:50L withTags:[NSSet setWithObject:@"pineapples"]];
                });

                it(@"update one item with no tag to an item with a tag while subscribed to a different tag", ^{
                    expectedGeofencesToStore[@7L] = oneOtherItemWithTagResponseData.geofences[0];
                    [[store should] receive:@selector(currentlyRegisteredGeofences) andReturn:oneItemGeofenceList];
                    [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                    [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                    [engine processResponseData:oneOtherItemWithTagResponseData withTimestamp:50L withTags:[NSSet setWithObject:@"ice cream"]];
                });

                it(@"update one item with no tag to an item with no tag while subscribed to a tag", ^{
                    [expectedGeofencesToRegister put:oneOtherItemWithNoTagResponseData.geofences[0] locationIndex:0];
                    expectedGeofencesToStore[@7L] = oneOtherItemWithNoTagResponseData.geofences[0];
                    [[store should] receive:@selector(currentlyRegisteredGeofences) andReturn:oneItemGeofenceList];
                    [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                    [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                    [engine processResponseData:oneOtherItemWithNoTagResponseData withTimestamp:50L withTags:[NSSet setWithObject:@"pineapples"]];
                });
            });

            context(@"tags (with no timestamp)", ^{

                beforeEach(^{
                    [[store should] receive:@selector(reset)];
                    [[registrar should] receive:@selector(reset)];
                });

                it(@"update one item with no items currently registered with a subscribed tag", ^{
                    [expectedGeofencesToRegister put:oneItemWithTagResponseData.geofences[0] locationIndex:0];
                    expectedGeofencesToStore[@7L] = oneItemWithTagResponseData.geofences[0];
                    [[store shouldNot] receive:@selector(currentlyRegisteredGeofences)];
                    [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                    [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                    [engine processResponseData:oneItemWithTagResponseData withTimestamp:0L withTags:[NSSet setWithObject:@"ice cream"]];
                });

                it(@"update one item with no items currently registered with an unsubscribed tag", ^{
                    expectedGeofencesToStore[@7L] = oneItemWithTagResponseData.geofences[0];
                    [[store shouldNot] receive:@selector(currentlyRegisteredGeofences)];
                    [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                    [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                    [engine processResponseData:oneItemWithTagResponseData withTimestamp:0L withTags:emptySubscribedTags];
                });
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
                    [engine processResponseData:complexResponseData withTimestamp:50L withTags:nil];
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
                    [engine processResponseData:complexResponseData withTimestamp:50L withTags:nil];
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
                    [engine processResponseData:complexResponseData withTimestamp:50L withTags:nil];
                });
            });

            context(@"filtering items with invalid data", ^{

                it(@"should filter items with insufficient data", ^{
                    [[store shouldNot] receive:@selector(reset)];
                    [[registrar shouldNot] receive:@selector(reset)];
                    [[store should] receive:@selector(currentlyRegisteredGeofences) andReturn:emptyGeofenceList];
                    [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                    [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                    [engine processResponseData:insufficientDataResponseData withTimestamp:50L withTags:nil];
                });

                it(@"should filter items with bad trigger type data", ^{
                    [[store shouldNot] receive:@selector(reset)];
                    [[registrar shouldNot] receive:@selector(reset)];
                    [[store should] receive:@selector(currentlyRegisteredGeofences) andReturn:oneItemGeofenceList];
                    [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                    [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                    [engine processResponseData:oneItemBadTriggerResponseData withTimestamp:50L withTags:nil];

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
                    [engine processResponseData:emptyResponseData withTimestamp:50L withTags:nil];
                });

                it(@"should filter expired items from updates", ^{
                    [expectedGeofencesToRegister put:complexResponseData.geofences[0] locationIndex:0];
                    expectedGeofencesToStore[@5L] = complexResponseData.geofences[0];
                    [[store should] receive:@selector(currentlyRegisteredGeofences) andReturn:emptyGeofenceList];
                    [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                    [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                    [engine processResponseData:complexResponseData withTimestamp:50L withTags:nil];
                });

                it(@"should filter expired items that are not expired but receive updates that are expired", ^{
                    [expectedGeofencesToRegister put:threeItemGeofenceList[@7L] locationIndex:0]; // Note that item ID 44 becomes expired in the update
                    [expectedGeofencesToRegister put:complexResponseData.geofences[0] locationIndex:0];
                    expectedGeofencesToStore[@7L] = threeItemGeofenceList[@7L];
                    expectedGeofencesToStore[@5L] = complexResponseData.geofences[0];
                    [[store should] receive:@selector(currentlyRegisteredGeofences) andReturn:threeItemGeofenceList];
                    [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                    [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                    [engine processResponseData:complexResponseData withTimestamp:50L withTags:nil];
                });

                it(@"should retain stored expired items that receive updates that are not expired", ^{
                    [expectedGeofencesToRegister put:fiveItemGeofenceList[@11L] locationIndex:0]; // Note that item ID 11 is kept from the store (including the 'old' version of item ID 5)
                    [expectedGeofencesToRegister put:complexResponseData.geofences[0] locationIndex:0]; // Note that item ID 5 is the only unexpired item in the update data
                    expectedGeofencesToStore[@11L] = fiveItemGeofenceList[@11L];
                    expectedGeofencesToStore[@5L] = complexResponseData.geofences[0];
                    [[store should] receive:@selector(currentlyRegisteredGeofences) andReturn:fiveItemGeofenceList];
                    [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                    [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                    [engine processResponseData:complexResponseData withTimestamp:50L withTags:nil];
                });
            });

            context(@"filter invalid items", ^{
                it(@"should filter invalid items from store", ^{
                    [[store should] receive:@selector(currentlyRegisteredGeofences) andReturn:oneItemBadRadiusGeofenceList];
                    [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                    [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                    [engine processResponseData:emptyResponseData withTimestamp:50L withTags:nil];
                });
            });
        });

        context(@"clearing items", ^{

            it(@"should do nothing if you try to clear a null list", ^{
                [[store shouldNot] receive:@selector(currentlyRegisteredGeofences)];
                [[store shouldNot] receive:@selector(saveRegisteredGeofences:)];
                [[registrar shouldNot] receive:@selector(registerGeofences:list:)];
                [engine clearLocations:nil withTags:nil];
            });

            it(@"should do nothing if you try to clear an empty list", ^{
                [[store shouldNot] receive:@selector(currentlyRegisteredGeofences)];
                [[store shouldNot] receive:@selector(saveRegisteredGeofences:)];
                [[registrar shouldNot] receive:@selector(registerGeofences:list:)];
                [engine clearLocations:[PCFPushGeofenceLocationMap map] withTags:nil];
            });

            it(@"should be able to clear one item", ^{
               [store stub:@selector(currentlyRegisteredGeofences) andReturn:fiveItemGeofenceList];

                PCFPushGeofenceLocationMap *oneItemMapToClear = [PCFPushGeofenceLocationMap map];
                [oneItemMapToClear put:fiveItemGeofenceList[@5L] locationIndex:0];

                expectedGeofencesToStore[@11L] = fiveItemGeofenceList[@11L];
                expectedGeofencesToStore[@44L] = fiveItemGeofenceList[@44L];
                expectedGeofencesToStore[@49L] = fiveItemGeofenceList[@49L];
                expectedGeofencesToStore[@51L] = fiveItemGeofenceList[@51L];

                expectedGeofencesToRegister = [PCFPushGeofenceLocationMap map];
                [expectedGeofencesToRegister put:fiveItemGeofenceList[@11L] locationIndex:0];

                [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];

                [engine clearLocations:oneItemMapToClear withTags:emptySubscribedTags];
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

                expectedGeofencesToRegister = [PCFPushGeofenceLocationMap map];
                [expectedGeofencesToRegister put:fiveItemGeofenceList[@5L] locationIndex:0];

                [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];

                [engine clearLocations:twoItemMapToClear withTags:emptySubscribedTags];
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

                [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];

                [engine clearLocations:sixItemMapToClear withTags:emptySubscribedTags];
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

                expectedGeofencesToRegister = [PCFPushGeofenceLocationMap map];
                [expectedGeofencesToRegister put:fiveItemGeofenceList[@5L] locationIndex:0];
                [expectedGeofencesToRegister put:fiveItemGeofenceList[@11L] locationIndex:0];

                [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];

                [engine clearLocations:twoItemMapToClear withTags:emptySubscribedTags];
            });

            it(@"should be able to clear one item while subscribed to a different tag", ^{
                [[store should] receive:@selector(currentlyRegisteredGeofences) andReturn:threeItemWithTagsGeofenceList];

                PCFPushGeofenceLocationMap *oneItemMapToClear = [PCFPushGeofenceLocationMap map];
                [oneItemMapToClear put:threeItemWithTagsGeofenceList[@9L] locationIndex:0];

                expectedGeofencesToStore[@7L] = threeItemWithTagsGeofenceList[@7L];
                expectedGeofencesToStore[@44L] = threeItemWithTagsGeofenceList[@44L];

                expectedGeofencesToRegister = [PCFPushGeofenceLocationMap mapWithGeofencesInList:expectedGeofencesToStore];

                [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];

                [engine clearLocations:oneItemMapToClear withTags:[NSSet setWithObject:@"ducks"]];
            });

            it(@"should be able to clear one item while subscribed to the items tag", ^{
                [[store should] receive:@selector(currentlyRegisteredGeofences) andReturn:threeItemWithTagsGeofenceList];

                PCFPushGeofenceLocationMap *oneItemMapToClear = [PCFPushGeofenceLocationMap map];
                [oneItemMapToClear put:threeItemWithTagsGeofenceList[@9L] locationIndex:0];

                expectedGeofencesToStore[@7L] = threeItemWithTagsGeofenceList[@7L];
                expectedGeofencesToStore[@44L] = threeItemWithTagsGeofenceList[@44L];

                [expectedGeofencesToRegister put:threeItemWithTagsGeofenceList[@44L] locationIndex:0];
                [expectedGeofencesToRegister put:threeItemWithTagsGeofenceList[@44L] locationIndex:1];

                [[store should] receive:@selector(saveRegisteredGeofences:) withArguments:expectedGeofencesToStore, nil];
                [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];

                [engine clearLocations:oneItemMapToClear withTags:[NSSet setWithObject:@"rats"]];
            });
        });

        context(@"reregistering", ^{

            beforeEach(^{
                [[store shouldNot] receive:@selector(reset)];
                [[registrar shouldNot] receive:@selector(reset)];
                [[store shouldNot] receive:@selector(saveRegisteredGeofences:)];
            });

            it(@"should do nothing if there are no currently stored geofences", ^{
                [[store should] receive:@selector(currentlyRegisteredGeofences) andReturn:emptyGeofenceList];
                [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                [engine reregisterCurrentLocationsWithTags:emptySubscribedTags];
            });

            it(@"should let you reregister the currently stored geofences", ^{
                [[store should] receive:@selector(currentlyRegisteredGeofences) andReturn:threeItemGeofenceList];

                [expectedGeofencesToRegister put:threeItemGeofenceList[@7L] locationIndex:0];
                [expectedGeofencesToRegister put:threeItemGeofenceList[@9L] locationIndex:0];
                [expectedGeofencesToRegister put:threeItemGeofenceList[@44L] locationIndex:0];
                [expectedGeofencesToRegister put:threeItemGeofenceList[@44L] locationIndex:1];

                expectedGeofencesToStore = threeItemGeofenceList;

                [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                [engine reregisterCurrentLocationsWithTags:emptySubscribedTags];
            });

            it(@"should only reregister those tagged locations that match the currently subscribed tags", ^{
                [[store should] receive:@selector(currentlyRegisteredGeofences) andReturn:oneItemWithTagGeofenceList];

                [expectedGeofencesToRegister put:oneItemWithTagGeofenceList[@7L] locationIndex:0];

                expectedGeofencesToStore = oneItemWithTagGeofenceList;

                [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                [engine reregisterCurrentLocationsWithTags:[NSSet setWithObject:@"pineapples"]];
            });

            it(@"should unregister tagged locations when there are no currently subscribed tags", ^{
                [[store should] receive:@selector(currentlyRegisteredGeofences) andReturn:oneItemWithTagGeofenceList];

                expectedGeofencesToStore = oneItemWithTagGeofenceList;

                [[registrar should] receive:@selector(registerGeofences:list:) withArguments:expectedGeofencesToRegister, expectedGeofencesToStore, nil];
                [engine reregisterCurrentLocationsWithTags:emptySubscribedTags];
            });
        });
    });

SPEC_END
