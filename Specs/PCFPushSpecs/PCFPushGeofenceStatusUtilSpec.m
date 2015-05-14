//
// Created by DX181-XL on 15-04-15.
//

#import "Kiwi.h"
#import "PCFPushGeofenceStatus.h"
#import "PCFPushGeofenceStatusUtil.h"
#import "PCFPushGeofenceDataList+Loaders.h"

typedef id (^FileExistsStubBlock)(NSArray*);

static FileExistsStubBlock fileExistsStubBlock(BOOL fileExists, BOOL isDirectory) {
    return ^id(NSArray *params) {
        BOOL *isDirectoryPointer = (BOOL *) [params[1] pointerValue];
        *isDirectoryPointer = isDirectory;
        return theValue(fileExists);
    };
}

SPEC_BEGIN(PCFPushGeofenceStatusUtilSpec)

    describe(@"PCFPushGeofenceStatusUtil", ^{

        __block PCFPushGeofenceStatus *status = [PCFPushGeofenceStatus statusWithError:YES errorReason:@"Stuff got broken" number:5];
        NSFileManager *fileManager = [NSFileManager mock];

        context(@"saving", ^{

            it(@"should be able to save a geofence status object", ^{

                [fileManager stub:@selector(URLsForDirectory:inDomains:) andReturn:@[[NSURL fileURLWithPath:@"/Library"]]];
                [fileManager stub:@selector(createFileAtPath:contents:attributes:) withBlock:^id(NSArray *params) {
                    NSError *error = nil;
                    NSString *path = params[0];
                    NSData *data = params[1];
                    [[path should] equal:@"/Library/PCF_PUSH_GEOFENCE/status.json"];
                    [[data shouldNot] beNil];
                    id dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                    [[dictionary shouldNot] beNil];
                    [[dictionary[@"isError"] should] equal:@YES];
                    [[dictionary[@"errorReason"] should] equal:@"Stuff got broken"];
                    [[dictionary[@"numberOfCurrentlyMonitoredGeofences"] should] equal:@5];
                    return theValue(YES);
                }];
                [[fileManager should] receive:@selector(createFileAtPath:contents:attributes:)];

                BOOL succeeded = [PCFPushGeofenceStatusUtil saveGeofenceStatus:status fileManager:fileManager];
                [[theValue(succeeded) should] beYes];
            });

            it(@"should return an error if it can't get the path", ^{

                [fileManager stub:@selector(URLsForDirectory:inDomains:)];
                [[fileManager shouldNot] receive:@selector(createFileAtPath:contents:attributes:)];

                BOOL succeeded = [PCFPushGeofenceStatusUtil saveGeofenceStatus:status fileManager:fileManager];
                [[theValue(succeeded) should] beNo];
            });

            it(@"should return an error if it can't save the file", ^{

                [fileManager stub:@selector(URLsForDirectory:inDomains:) andReturn:@[[NSURL fileURLWithPath:@"/Library"]]];
                [[fileManager should] receive:@selector(createFileAtPath:contents:attributes:) andReturn:theValue(NO)];

                BOOL succeeded = [PCFPushGeofenceStatusUtil saveGeofenceStatus:status fileManager:fileManager];
                [[theValue(succeeded) should] beNo];
            });

            it(@"should return an error if it can't serialize the status object", ^{

                [fileManager stub:@selector(URLsForDirectory:inDomains:) andReturn:@[[NSURL fileURLWithPath:@"/Library"]]];
                [[fileManager shouldNot] receive:@selector(createFileAtPath:contents:attributes:)];
                [NSJSONSerialization stub:@selector(dataWithJSONObject:options:error:)];

                BOOL succeeded = [PCFPushGeofenceStatusUtil saveGeofenceStatus:status fileManager:fileManager];
                [[theValue(succeeded) should] beNo];
            });

            it(@"should require a status object to save", ^{

                [fileManager stub:@selector(URLsForDirectory:inDomains:) andReturn:@[[NSURL fileURLWithPath:@"/Library"]]];
                [[fileManager shouldNot] receive:@selector(createFileAtPath:contents:attributes:)];

                BOOL succeeded = [PCFPushGeofenceStatusUtil saveGeofenceStatus:nil fileManager:fileManager];
                [[theValue(succeeded) should] beNo];
            });

            it(@"should require a file manager object", ^{

                [fileManager stub:@selector(URLsForDirectory:inDomains:) andReturn:@[[NSURL fileURLWithPath:@"/Library"]]];
                [[fileManager shouldNot] receive:@selector(createFileAtPath:contents:attributes:)];

                BOOL succeeded = [PCFPushGeofenceStatusUtil saveGeofenceStatus:status fileManager:nil];
                [[theValue(succeeded) should] beNo];
            });
        });

        context(@"loading", ^{

            __block NSData *geofenceStatusData;

            it(@"should be able to load a geofence status", ^{
                geofenceStatusData =loadTestFile([self class], @"geofence_status");
                [fileManager stub:@selector(fileExistsAtPath:isDirectory:) withBlock:fileExistsStubBlock(YES, NO)];
                [NSData stub:@selector(dataWithContentsOfFile:options:error:) andReturn:geofenceStatusData];
                [fileManager stub:@selector(URLsForDirectory:inDomains:) andReturn:@[[NSURL fileURLWithPath:@"/Library"]]];
                [[NSData should] receive:@selector(dataWithContentsOfFile:options:error:) withArguments:@"/Library/PCF_PUSH_GEOFENCE/status.json", any(), any(), nil];

                status = [PCFPushGeofenceStatusUtil loadGeofenceStatus:fileManager];
                [[status shouldNot] beNil];
                [[theValue(status.isError) should] beYes];
                [[status.errorReason should] equal:@"It's broken!"];
                [[theValue(status.numberOfCurrentlyMonitoredGeofences) should] equal:theValue(5)];
            });

            it(@"should give an empty status is a file manager is not provided", ^{
                [[NSData shouldNot] receive:@selector(dataWithContentsOfFile:options:error:)];
                status = [PCFPushGeofenceStatusUtil loadGeofenceStatus:nil];
                [[status should] equal:[PCFPushGeofenceStatus emptyStatus]];
            });

            it(@"should give an empty status if there is no geofences path", ^{
                [fileManager stub:@selector(URLsForDirectory:inDomains:)];
                [[fileManager shouldNot] receive:@selector(fileExistsAtPath:isDirectory:)];
                [[NSData shouldNot] receive:@selector(dataWithContentsOfFile:options:error:)];
                status = [PCFPushGeofenceStatusUtil loadGeofenceStatus:fileManager];
                [[status should] equal:[PCFPushGeofenceStatus emptyStatus]];
            });

            it(@"should give an empty status if there is no geofences file", ^{
                [fileManager stub:@selector(URLsForDirectory:inDomains:) andReturn:@[[NSURL fileURLWithPath:@"/Library"]]];
                [fileManager stub:@selector(fileExistsAtPath:isDirectory:) withBlock:fileExistsStubBlock(NO, NO)];
                [[NSData shouldNot] receive:@selector(dataWithContentsOfFile:options:error:)];
                status = [PCFPushGeofenceStatusUtil loadGeofenceStatus:fileManager];
                [[status should] equal:[PCFPushGeofenceStatus emptyStatus]];
            });

            it(@"should give an empty status if the geofences file is a directory", ^{
                [fileManager stub:@selector(URLsForDirectory:inDomains:) andReturn:@[[NSURL fileURLWithPath:@"/Library"]]];
                [fileManager stub:@selector(fileExistsAtPath:isDirectory:) withBlock:fileExistsStubBlock(YES, YES)];
                [[NSData shouldNot] receive:@selector(dataWithContentsOfFile:options:error:)];
                status = [PCFPushGeofenceStatusUtil loadGeofenceStatus:fileManager];
                [[status should] equal:[PCFPushGeofenceStatus emptyStatus]];
            });

            it(@"should give an empty status if the geofences file can't be loaded", ^{
                [fileManager stub:@selector(URLsForDirectory:inDomains:) andReturn:@[[NSURL fileURLWithPath:@"/Library"]]];
                [fileManager stub:@selector(fileExistsAtPath:isDirectory:) withBlock:fileExistsStubBlock(YES, NO)];
                [[NSData should] receive:@selector(dataWithContentsOfFile:options:error:) withArguments:@"/Library/PCF_PUSH_GEOFENCE/status.json", any(), any(), nil];
                [NSData stub:@selector(dataWithContentsOfFile:options:error:)]; // Returns nil
                status = [PCFPushGeofenceStatusUtil loadGeofenceStatus:fileManager];
                [[status should] equal:[PCFPushGeofenceStatus emptyStatus]];
            });

            it(@"should give an empty status if the geofences file can't be deserialized", ^{
                [fileManager stub:@selector(URLsForDirectory:inDomains:) andReturn:@[[NSURL fileURLWithPath:@"/Library"]]];
                [fileManager stub:@selector(fileExistsAtPath:isDirectory:) withBlock:fileExistsStubBlock(YES, NO)];
                [[NSData should] receive:@selector(dataWithContentsOfFile:options:error:) withArguments:@"/Library/PCF_PUSH_GEOFENCE/status.json", any(), any(), nil];
                [NSData stub:@selector(dataWithContentsOfFile:options:error:) andReturn:[@"I AM NOT JSON" dataUsingEncoding:NSUTF8StringEncoding]];
                status = [PCFPushGeofenceStatusUtil loadGeofenceStatus:fileManager];
                [[status should] equal:[PCFPushGeofenceStatus emptyStatus]];
            });
        });
    });

SPEC_END