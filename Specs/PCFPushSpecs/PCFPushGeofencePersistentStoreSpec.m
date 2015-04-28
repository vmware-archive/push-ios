#import "PCFPushGeofenceData.h"//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "Kiwi.h"

#import "PCFPushGeofencePersistentStore.h"
#import "PCFPushSpecsHelper.h"
#import "PCFPushGeofenceDataList.h"
#import "PCFPushGeofenceDataList+Loaders.h"

SPEC_BEGIN(PCFPushGeofencePersistentStoreSpec)

describe(@"PCFPushGeofencePersistentStore", ^{

    //__block PCFPushSpecsHelper *helper;
    __block PCFPushGeofencePersistentStore *store;
    __block NSFileManager *fileManager;

    beforeEach(^{
        //helper = [[PCFPushSpecsHelper alloc] init];
        fileManager = [[NSFileManager alloc] init];
        store = [[PCFPushGeofencePersistentStore alloc] initWithFileManager:fileManager];
    });

    context(@"directory management", ^{

        it(@"should return nil if we can't find the library directory (returned nil)", ^{
            [fileManager stub:@selector(URLsForDirectory:inDomains:)];
            [[fileManager shouldNot] receive:@selector(createDirectoryAtPath:withIntermediateDirectories:attributes:error:)];
            [[fileManager shouldNot] receive:@selector(contentsOfDirectoryAtPath:error:)];
            [[[store currentlyRegisteredGeofences] should] beNil];
        });

        it(@"should return nil if we can't find the library directory (returned an empty array)", ^{
            [fileManager stub:@selector(URLsForDirectory:inDomains:) andReturn:@[]];
            [[fileManager shouldNot] receive:@selector(createDirectoryAtPath:withIntermediateDirectories:attributes:error:)];
            [[fileManager shouldNot] receive:@selector(contentsOfDirectoryAtPath:error:)];
            [[[store currentlyRegisteredGeofences] should] beNil];
        });

        it(@"should return nil if we can't create the data directory", ^{
            [fileManager stub:@selector(URLsForDirectory:inDomains:) andReturn:@[@"/Library"]];
            [fileManager stub:@selector(createDirectoryAtPath:withIntermediateDirectories:attributes:error:) andReturn:theValue(NO)];
            [[fileManager shouldNot] receive:@selector(contentsOfDirectoryAtPath:error:)];
            [[[store currentlyRegisteredGeofences] should] beNil];
        });

        it(@"should return nil if we can't read the data directory", ^{
            [fileManager stub:@selector(URLsForDirectory:inDomains:) andReturn:@[@"/Library"]];
            [fileManager stub:@selector(createDirectoryAtPath:withIntermediateDirectories:attributes:error:) andReturn:theValue(YES)];
            [fileManager stub:@selector(contentsOfDirectoryAtPath:error:)];
            [[[store currentlyRegisteredGeofences] should] beNil];
        });

    });

    context(@"getting currently registered geofences", ^{

        beforeEach(^{
            [fileManager stub:@selector(URLsForDirectory:inDomains:) andReturn:@[@"/Library"]];
            [fileManager stub:@selector(createDirectoryAtPath:withIntermediateDirectories:attributes:error:) andReturn:theValue(YES)];
        });

        it(@"should return an empty geofence data list when no geofences are registered", ^{
            [fileManager stub:@selector(contentsOfDirectoryAtPath:error:) andReturn:@[]];
            PCFPushGeofenceDataList *geofences = [store currentlyRegisteredGeofences];
            [[geofences shouldNot] beNil];
            [[theValue(geofences.count) should] beZero];
        });

        it(@"should return one file if one geofence is registered", ^{
            [fileManager stub:@selector(contentsOfDirectoryAtPath:error:) andReturn:@[@"PCF_PUSH_GEOFENCE_1.json"]];
            [NSData stub:@selector(dataWithContentsOfFile:) andReturn:loadTestFile([self class], @"geofence_one_item_persisted_1")];
            PCFPushGeofenceDataList *geofences = [store currentlyRegisteredGeofences];
            [[geofences should] haveCountOf:1];
            [[theValue(((PCFPushGeofenceData *) (geofences[@1])).id) should] equal:theValue(1)];
        });

        it(@"should return three files if three geofences are registered", ^{
            [fileManager stub:@selector(contentsOfDirectoryAtPath:error:) andReturn:@[@"PCF_PUSH_GEOFENCE_1.json", @"PCF_PUSH_GEOFENCE_2.json", @"PCF_PUSH_GEOFENCE_3.json"]];
            [NSData stub:@selector(dataWithContentsOfFile:) withBlock:^id(NSArray *params) {
                if ([params[0] hasSuffix:@"PCF_PUSH_GEOFENCE_1.json"]) {
                    return loadTestFile([self class], @"geofence_one_item_persisted_1");
                } else if ([params[0] hasSuffix:@"PCF_PUSH_GEOFENCE_2.json"]) {
                    return loadTestFile([self class], @"geofence_one_item_persisted_2");
                } else if ([params[0] hasSuffix:@"PCF_PUSH_GEOFENCE_3.json"]) {
                    return loadTestFile([self class], @"geofence_one_item_persisted_3");
                } else {
                    fail(@"Tried to read file that doesn't exist");
                    return nil;
                }
            }];
            PCFPushGeofenceDataList *geofences = [store currentlyRegisteredGeofences];
            [[geofences should] haveCountOf:3];
            [[theValue(((PCFPushGeofenceData *) (geofences[@1])).id) should] equal:theValue(1)];
            [[theValue(((PCFPushGeofenceData *) (geofences[@2])).id) should] equal:theValue(2)];
            [[theValue(((PCFPushGeofenceData *) (geofences[@3])).id) should] equal:theValue(3)];
        });

        it(@"should ignore filenames that don't exist", ^{
            [fileManager stub:@selector(contentsOfDirectoryAtPath:error:) andReturn:@[@"PCF_PUSH_GEOFENCE_1.json", @"imposter.json", @"PCF_PUSH_GEOFENCE_something_else"]];
            [NSData stub:@selector(dataWithContentsOfFile:) withBlock:^id(NSArray *params) {
                if ([params[0] hasSuffix:@"PCF_PUSH_GEOFENCE_1.json"]) {
                    return loadTestFile([self class], @"geofence_one_item_persisted_1");
                } else {
                    fail(@"Tried to read file that doesn't exist");
                    return nil;
                }
            }];
            PCFPushGeofenceDataList *geofences = [store currentlyRegisteredGeofences];
            [[geofences should] haveCountOf:1];
            [[theValue(((PCFPushGeofenceData *) (geofences[@1])).id) should] equal:theValue(1)];
        });

        it(@"should ignore filenames that don't load", ^{
            [fileManager stub:@selector(contentsOfDirectoryAtPath:error:) andReturn:@[@"PCF_PUSH_GEOFENCE_2.json", @"PCF_PUSH_GEOFENCE_9.json"]];
            [NSData stub:@selector(dataWithContentsOfFile:) withBlock:^id(NSArray *params) {
                if ([params[0] hasSuffix:@"PCF_PUSH_GEOFENCE_2.json"]) {
                    return loadTestFile([self class], @"geofence_one_item_persisted_2");
                } else if ([params[0] hasSuffix:@"PCF_PUSH_GEOFENCE_9.json"]) {
                    return [@"THIS IS NOT JSON" dataUsingEncoding:NSUTF8StringEncoding];
                } else {
                    fail(@"Tried to read file that doesn't exist");
                    return nil;
                }
            }];
            PCFPushGeofenceDataList *geofences = [store currentlyRegisteredGeofences];
            [[geofences should] haveCountOf:1];
            [[theValue(((PCFPushGeofenceData *) (geofences[@2])).id) should] equal:theValue(2)];
        });
    });

});

SPEC_END
