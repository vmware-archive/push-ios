#import "PCFPushGeofenceData.h"//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "Kiwi.h"

#import "PCFPushGeofencePersistentStore.h"
#import "PCFPushGeofenceDataList.h"
#import "PCFPushGeofenceDataList+Loaders.h"
#import "NSObject+PCFJSONizable.h"

typedef id (^FileExistsStubBlock)(NSArray*);

static FileExistsStubBlock fileExistsStubBlock(BOOL fileExists, BOOL isDirectory) {
    return ^id(NSArray *params) {
        BOOL *isDirectoryPointer = (BOOL *) [params[1] pointerValue];
        *isDirectoryPointer = isDirectory;
        return theValue(fileExists);
    };
}

SPEC_BEGIN(PCFPushGeofencePersistentStoreSpec)

describe(@"PCFPushGeofencePersistentStore", ^{

    __block PCFPushGeofencePersistentStore *store;
    __block NSFileManager *fileManager;
    __block PCFPushGeofenceDataList *oneItemDataList;
    __block PCFPushGeofenceDataList *threeItemDataList;
    __block NSData *persistedGeofenceData;

    beforeEach(^{
        fileManager = [[NSFileManager alloc] init];
        store = [[PCFPushGeofencePersistentStore alloc] initWithFileManager:fileManager];
        oneItemDataList = loadGeofenceList([self class], @"geofence_one_item");
        threeItemDataList = loadGeofenceList([self class], @"geofence_three_items");
        persistedGeofenceData =loadTestFile([self class], @"geofence_one_item_persisted_3");
    });

    context(@"directory management", ^{

        context(@"when the library directory is nil", ^{

            beforeEach(^{
                [fileManager stub:@selector(URLsForDirectory:inDomains:)];
                [[fileManager shouldNot] receive:@selector(fileExistsAtPath:isDirectory:)];
                [[fileManager shouldNot] receive:@selector(createDirectoryAtPath:withIntermediateDirectories:attributes:error:)];
                [[fileManager shouldNot] receive:@selector(contentsOfDirectoryAtPath:error:)];
            });

            it(@"should return nil when calling currentlyRegisteredGeofences", ^{
                [[[store currentlyRegisteredGeofences] should] beNil];
            });

            it(@"should do nothing when calling reset", ^{
                [store reset];
                [[fileManager shouldNot] receive:@selector(removeItemAtPath:error:)];
            });

            it(@"should do nothing when calling save", ^{
                [store saveRegisteredGeofences:threeItemDataList];
                [[fileManager shouldNot] receive:@selector(removeItemAtPath:error:)];
                [[fileManager shouldNot] receive:@selector(createFileAtPath:contents:attributes:)];
            });

            it(@"should return nil when getting a geofence", ^{
                [[store[@7L] should] beNil];
            });
        });

        context(@"when the library directory list is empty", ^{

            beforeEach(^{
                [fileManager stub:@selector(URLsForDirectory:inDomains:) andReturn:@[]];
                [[fileManager shouldNot] receive:@selector(fileExistsAtPath:isDirectory:)];
                [[fileManager shouldNot] receive:@selector(createDirectoryAtPath:withIntermediateDirectories:attributes:error:)];
                [[fileManager shouldNot] receive:@selector(contentsOfDirectoryAtPath:error:)];
            });

            it(@"should return nil when calling currentlyRegisteredGeofences", ^{
                [[[store currentlyRegisteredGeofences] should] beNil];
            });

            it(@"should do nothing when calling reset", ^{
                [store reset];
                [[fileManager shouldNot] receive:@selector(removeItemAtPath:error:)];
            });

            it(@"should do nothing when calling save", ^{
                [store saveRegisteredGeofences:threeItemDataList];
                [[fileManager shouldNot] receive:@selector(removeItemAtPath:error:)];
                [[fileManager shouldNot] receive:@selector(createFileAtPath:contents:attributes:)];
            });
        });

        context(@"when the geofences directory does not exist", ^{

            beforeEach(^{
                [fileManager stub:@selector(URLsForDirectory:inDomains:) andReturn:@[[NSURL fileURLWithPath:@"/Library"]]];
                [fileManager stub:@selector(fileExistsAtPath:isDirectory:) withBlock:fileExistsStubBlock(NO, NO)];
                [[fileManager shouldNot] receive:@selector(createDirectoryAtPath:withIntermediateDirectories:attributes:error:)];
                [[fileManager shouldNot] receive:@selector(contentsOfDirectoryAtPath:error:)];
            });

            it(@"should return nil when calling currentlyRegisteredGeofences", ^{
                [[[store currentlyRegisteredGeofences] should] beNil];
            });

            it(@"should do nothing when calling reset", ^{
                [store reset];
                [[fileManager shouldNot] receive:@selector(removeItemAtPath:error:)];
            });
        });

        context(@"when the geofences directory is not a directory", ^{

            beforeEach(^{
                [fileManager stub:@selector(URLsForDirectory:inDomains:) andReturn:@[[NSURL fileURLWithPath:@"/Library"]]];
                [fileManager stub:@selector(fileExistsAtPath:isDirectory:) withBlock:fileExistsStubBlock(YES, NO)];
                [[fileManager shouldNot] receive:@selector(createDirectoryAtPath:withIntermediateDirectories:attributes:error:)];
                [[fileManager shouldNot] receive:@selector(contentsOfDirectoryAtPath:error:)];
            });

            it(@"should return nil when calling currentlyRegisteredGeofences", ^{
                [[[store currentlyRegisteredGeofences] should] beNil];
            });

            it(@"should do nothing when calling reset", ^{
                [store reset];
                [[fileManager shouldNot] receive:@selector(removeItemAtPath:error:)];
            });
        });

        context(@"when the data directory can't be created", ^{

            beforeEach(^{
                [fileManager stub:@selector(URLsForDirectory:inDomains:) andReturn:@[[NSURL fileURLWithPath:@"/Library"]]];
                [[fileManager shouldNot] receive:@selector(fileExistsAtPath:isDirectory:)];
                [fileManager stub:@selector(createDirectoryAtPath:withIntermediateDirectories:attributes:error:) andReturn:theValue(NO)];
                [[fileManager shouldNot] receive:@selector(contentsOfDirectoryAtPath:error:)];
            });

            it(@"should do nothing when calling save", ^{
                [store saveRegisteredGeofences:threeItemDataList];
                [[fileManager shouldNot] receive:@selector(removeItemAtPath:error:)];
                [[fileManager shouldNot] receive:@selector(createFileAtPath:contents:attributes:)];
            });
        });

        context(@"when the data directory can't be scanned", ^{

            beforeEach(^{
                [fileManager stub:@selector(URLsForDirectory:inDomains:) andReturn:@[[NSURL fileURLWithPath:@"/Library"]]];
                [fileManager stub:@selector(contentsOfDirectoryAtPath:error:)];
            });

            it(@"should return nil when calling currentlyRegisteredGeofences", ^{
                [fileManager stub:@selector(fileExistsAtPath:isDirectory:) withBlock:fileExistsStubBlock(YES, YES)];
                [[fileManager shouldNot] receive:@selector(createDirectoryAtPath:withIntermediateDirectories:attributes:error:)];
                [[fileManager should] receive:@selector(fileExistsAtPath:isDirectory:) withCount:1];
                [[[store currentlyRegisteredGeofences] should] beNil];
            });

            it(@"should do nothing when calling reset", ^{
                [fileManager stub:@selector(fileExistsAtPath:isDirectory:) withBlock:fileExistsStubBlock(YES, YES)];
                [[fileManager shouldNot] receive:@selector(createDirectoryAtPath:withIntermediateDirectories:attributes:error:)];
                [[fileManager should] receive:@selector(fileExistsAtPath:isDirectory:) withCount:1];
                [[fileManager shouldNot] receive:@selector(removeItemAtPath:error:)];
                [store reset];
            });

            it(@"should do nothing when calling save", ^{
                [fileManager stub:@selector(createDirectoryAtPath:withIntermediateDirectories:attributes:error:) andReturn:theValue(YES)];
                [[fileManager shouldNot] receive:@selector(fileExistsAtPath:isDirectory:)];
                [[fileManager shouldNot] receive:@selector(removeItemAtPath:error:)];
                [[fileManager shouldNot] receive:@selector(createFileAtPath:contents:attributes:)];
                [store saveRegisteredGeofences:threeItemDataList];
            });
        });
    });

    context(@"getting a geofence", ^{

        beforeEach(^{
            [fileManager stub:@selector(URLsForDirectory:inDomains:) andReturn:@[[NSURL fileURLWithPath:@"/Library"]]];
        });

        it(@"should return nil if a geofence does exist with the given ID", ^{
            [NSData stub:@selector(dataWithContentsOfFile:options:error:) withBlock:^id(NSArray *params) {
                NSError * __autoreleasing * error = (NSError * __autoreleasing *) [params[2] pointerValue];
                *error = [NSError errorWithDomain:@"File not found" code:0 userInfo:nil];
                return nil;
            }];
            [[store[@10L] should] beNil];
        });

        it(@"should return nil if the JSON data does not parse", ^{
            [NSData stub:@selector(dataWithContentsOfFile:options:error:) andReturn:[@"I AM NOT JSON" dataUsingEncoding:NSUTF8StringEncoding]];
            [[store[@23L] should] beNil];
        });

        it(@"should load a geofence that exists with the given ID", ^{
            [NSData stub:@selector(dataWithContentsOfFile:options:error:) andReturn:persistedGeofenceData];
            PCFPushGeofenceData *geofence = store[@3L];
            [[geofence shouldNot] beNil];
            [[theValue(geofence.id) should] equal:theValue(3L)];
        });
    });

    context(@"getting currently registered geofences", ^{

        beforeEach(^{
            [fileManager stub:@selector(URLsForDirectory:inDomains:) andReturn:@[[NSURL fileURLWithPath:@"/Library"]]];
            [fileManager stub:@selector(fileExistsAtPath:isDirectory:) withBlock:fileExistsStubBlock(YES, YES)];
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
            [fileManager stub:@selector(contentsOfDirectoryAtPath:error:) andReturn:@[
                    @"PCF_PUSH_GEOFENCE_1.json",
                    @"PCF_PUSH_GEOFENCE_2.json",
                    @"PCF_PUSH_GEOFENCE_3.json"]];

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
            [fileManager stub:@selector(contentsOfDirectoryAtPath:error:) andReturn:@[
                    @"PCF_PUSH_GEOFENCE_1.json",
                    @"imposter.json",
                    @"PCF_PUSH_GEOFENCE_something_else"]];

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
            [fileManager stub:@selector(contentsOfDirectoryAtPath:error:) andReturn:@[
                    @"PCF_PUSH_GEOFENCE_2.json",
                    @"PCF_PUSH_GEOFENCE_9.json"]];

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

    context(@"resetting geofences", ^{

        beforeEach(^{
            [fileManager stub:@selector(URLsForDirectory:inDomains:) andReturn:@[[NSURL fileURLWithPath:@"/Library"]]];
            [fileManager stub:@selector(fileExistsAtPath:isDirectory:) withBlock:fileExistsStubBlock(YES, YES)];
        });

        it(@"should be able to reset when there are no stored geofences", ^{
            [fileManager stub:@selector(contentsOfDirectoryAtPath:error:) andReturn:@[]];
            [[fileManager shouldNot] receive:@selector(removeItemAtPath:error:)];
            [store reset];
        });

        it(@"should be able to reset when there is one stored geofence", ^{
            [fileManager stub:@selector(contentsOfDirectoryAtPath:error:) andReturn:@[@"PCF_PUSH_GEOFENCE_1.json"]];
            [[fileManager should] receive:@selector(removeItemAtPath:error:) withCount:1];
            [store reset];
        });

        it(@"should be able to reset when there are three stored geofences", ^{

            [fileManager stub:@selector(contentsOfDirectoryAtPath:error:) andReturn:@[
                    @"PCF_PUSH_GEOFENCE_1.json",
                    @"PCF_PUSH_GEOFENCE_2.json",
                    @"PCF_PUSH_GEOFENCE_3.json"]];

            [[fileManager should] receive:@selector(removeItemAtPath:error:) withCount:3];
            [store reset];
        });
    });

    context(@"saving geofences", ^{

        id (^const createFileStub)(NSArray *) = ^id(NSArray *params) {
            NSError *error = nil;
            NSString *path = params[0];
            PCFPushGeofenceData *data = [PCFPushGeofenceData pcf_fromJSONData:params[1] error:&error];
            [[error should] beNil];
            if ([path isEqualToString:@"/Library/PCF_PUSH_GEOFENCE/PCF_PUSH_GEOFENCE_7.json"]) {
                [[theValue(data.id) should] equal:theValue(7L)];
            } else if ([path isEqualToString:@"/Library/PCF_PUSH_GEOFENCE/PCF_PUSH_GEOFENCE_9.json"]) {
                [[theValue(data.id) should] equal:theValue(9L)];
            } else if ([path isEqualToString:@"/Library/PCF_PUSH_GEOFENCE/PCF_PUSH_GEOFENCE_44.json"]) {
                [[theValue(data.id) should] equal:theValue(44L)];
            } else {
                fail(@"unexpected filename");
            }
            return theValue(YES);
        };

        beforeEach(^{
            [fileManager stub:@selector(URLsForDirectory:inDomains:) andReturn:@[[NSURL fileURLWithPath:@"/Library"]]];
            [fileManager stub:@selector(createDirectoryAtPath:withIntermediateDirectories:attributes:error:) andReturn:theValue(YES)];
            [[fileManager shouldNot] receive:@selector(fileExistsAtPath:isDirectory:)];
        });

        it(@"should do nothing if given a nil list of geofences", ^{
            [store saveRegisteredGeofences:nil];
            [[fileManager shouldNot] receive:@selector(contentsOfDirectoryAtPath:error:)];
            [[fileManager shouldNot] receive:@selector(createFileAtPath:contents:attributes:)];
            [[fileManager shouldNot] receive:@selector(removeItemAtPath:error:)];
        });

        it(@"should save one file and delete no files if there are no currently saved geofences", ^{
            [fileManager stub:@selector(contentsOfDirectoryAtPath:error:) andReturn:@[]];
            [fileManager stub:@selector(createFileAtPath:contents:attributes:) withBlock:^id(NSArray *params) {
                NSError *error = nil;
                NSString *path = params[0];
                [[path should] equal:@"/Library/PCF_PUSH_GEOFENCE/PCF_PUSH_GEOFENCE_7.json"];
                PCFPushGeofenceData *data = [PCFPushGeofenceData pcf_fromJSONData:params[1] error:&error];
                [[error should] beNil];
                [[theValue(data.id) should] equal:theValue(7L)];
                return theValue(YES);
            }];
            [[fileManager shouldNot] receive:@selector(removeItemAtPath:error:)];
            [[fileManager should] receive:@selector(createFileAtPath:contents:attributes:) withCount:1];
            [store saveRegisteredGeofences:oneItemDataList];
        });

        it(@"should save three files and delete no files if there are no currently saved geofences", ^{
            [fileManager stub:@selector(contentsOfDirectoryAtPath:error:) andReturn:@[]];
            [fileManager stub:@selector(createFileAtPath:contents:attributes:) withBlock:createFileStub];
            [[fileManager shouldNot] receive:@selector(removeItemAtPath:error:)];
            [[fileManager should] receive:@selector(createFileAtPath:contents:attributes:) withCount:3];
            [store saveRegisteredGeofences:threeItemDataList];
        });

        it(@"should save three files and delete three pre-existing files", ^{
            [fileManager stub:@selector(contentsOfDirectoryAtPath:error:) andReturn:@[
                    @"PCF_PUSH_GEOFENCE_0.json",
                    @"PCF_PUSH_GEOFENCE_53.json",
                    @"PCF_PUSH_GEOFENCE_127.json"]];

            __block NSMutableArray *removedFilenames = [NSMutableArray array];
            NSArray *expectedRemovedFilenames = @[
                    @"/Library/PCF_PUSH_GEOFENCE/PCF_PUSH_GEOFENCE_0.json",
                    @"/Library/PCF_PUSH_GEOFENCE/PCF_PUSH_GEOFENCE_53.json",
                    @"/Library/PCF_PUSH_GEOFENCE/PCF_PUSH_GEOFENCE_127.json"];

            [fileManager stub:@selector(removeItemAtPath:error:) withBlock:^id(NSArray *params) {
                [removedFilenames addObject:params[0]];
                return theValue(YES);
            }];


            [fileManager stub:@selector(createFileAtPath:contents:attributes:) withBlock:createFileStub];
            [[fileManager should] receive:@selector(removeItemAtPath:error:) withCount:3];
            [[fileManager should] receive:@selector(createFileAtPath:contents:attributes:) withCount:3];
            [store saveRegisteredGeofences:threeItemDataList];

            [[removedFilenames should] containObjectsInArray:expectedRemovedFilenames];
        });

        it(@"should save two new files, replace one file and delete two pre-existing files", ^{
            [fileManager stub:@selector(contentsOfDirectoryAtPath:error:) andReturn:@[
                    @"PCF_PUSH_GEOFENCE_7.json",
                    @"PCF_PUSH_GEOFENCE_53.json",
                    @"PCF_PUSH_GEOFENCE_127.json"]];

            __block NSMutableArray *removedFilenames = [NSMutableArray array];

            NSArray *expectedRemovedFilenames = @[
                    @"/Library/PCF_PUSH_GEOFENCE/PCF_PUSH_GEOFENCE_53.json",
                    @"/Library/PCF_PUSH_GEOFENCE/PCF_PUSH_GEOFENCE_127.json"];

            [fileManager stub:@selector(removeItemAtPath:error:) withBlock:^id(NSArray *params) {
                [removedFilenames addObject:params[0]];
                return theValue(YES);
            }];

            [fileManager stub:@selector(createFileAtPath:contents:attributes:) withBlock:createFileStub];
            [[fileManager should] receive:@selector(removeItemAtPath:error:) withCount:2];
            [[fileManager should] receive:@selector(createFileAtPath:contents:attributes:) withCount:3];
            [store saveRegisteredGeofences:threeItemDataList];

            [[removedFilenames should] containObjectsInArray:expectedRemovedFilenames];
        });

        it(@"should replace three files and delete no files", ^{
            [fileManager stub:@selector(contentsOfDirectoryAtPath:error:) andReturn:@[
                    @"PCF_PUSH_GEOFENCE_7.json",
                    @"PCF_PUSH_GEOFENCE_9.json",
                    @"PCF_PUSH_GEOFENCE_44.json"]];

            [fileManager stub:@selector(createFileAtPath:contents:attributes:) withBlock:createFileStub];
            [[fileManager shouldNot] receive:@selector(removeItemAtPath:error:)];
            [[fileManager should] receive:@selector(createFileAtPath:contents:attributes:) withCount:3];
            [store saveRegisteredGeofences:threeItemDataList];
        });
    });
});

SPEC_END
