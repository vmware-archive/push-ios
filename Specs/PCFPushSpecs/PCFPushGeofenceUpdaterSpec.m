//
// Created by DX181-XL on 15-04-15.
//

#import "Kiwi.h"
#import "PCFPushGeofenceUpdater.h"
#import "PCFPushGeofenceEngine.h"
#import "PCFPushURLConnection.h"
#import "PCFPushSpecsHelper.h"
#import "PCFPushGeofenceResponseData.h"
#import "PCFPushPersistentStorage.h"
#import "PCFPushGeofenceStatusUtil.h"
#import "PCFPushGeofenceStatus.h"

typedef id (^GeofenceRequestStub)(NSArray *params);

static GeofenceRequestStub successfulGeofenceRequestStub(NSUInteger httpStatus, NSData *data, void (^block)())
{
    return ^id(NSArray *params) {
        if (block) {
            block();
        }
        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:httpStatus HTTPVersion:nil headerFields:nil];
        void(^completionHandler)(NSURLResponse *, NSData *) = params[3];
        completionHandler(response, data);
        return nil;
    };
}

static GeofenceRequestStub failedGeofenceRequestStub(void (^block)())
{
    return ^id(NSArray *params) {
        if (block) {
            block();
        }
        void(^completionHandler)(NSError *) = params[4];
        completionHandler([NSError errorWithDomain:@"Fake request failed fakely" code:0 userInfo:nil]);
        return nil;
    };
}

SPEC_BEGIN(PCFPushGeofenceUpdaterSpec)

    describe(@"PCFPushGeofenceUpdater", ^{

        __block PCFPushGeofenceEngine *engine;
        __block PCFPushSpecsHelper *helper;

        beforeEach(^{
            helper = [[PCFPushSpecsHelper alloc] init];
            [helper setupDefaultPLIST];
        });

        afterEach(^{
            [helper reset];
        });

        context(@"checking arguments on the start update method", ^{

            beforeEach(^{
                engine = [PCFPushGeofenceEngine mock];
                [engine stub:@selector(processResponseData:withTimestamp:withTags:)];
                [PCFPushURLConnection stub:@selector(geofenceRequestWithParameters:timestamp:deviceUuid:success:failure:) withBlock:successfulGeofenceRequestStub(200, [NSData data], nil)];
            });

            it(@"should require a geofence engine", ^{
                [[theBlock(^{
                    [PCFPushGeofenceUpdater startGeofenceUpdate:nil userInfo:@{} timestamp:0L tags:[NSSet set] success:^{} failure:^(NSError *error) {}];
                }) should] raise];
            });

            it(@"should not require a userdata object", ^{
                [[theBlock(^{
                    [PCFPushGeofenceUpdater startGeofenceUpdate:engine userInfo:nil timestamp:0L tags:[NSSet set] success:^{} failure:^(NSError *error) {}];
                }) shouldNot] raise];
            });

            it(@"should not require tags", ^{
                [[theBlock(^{
                    [PCFPushGeofenceUpdater startGeofenceUpdate:engine userInfo:@{} timestamp:0L tags:nil success:^{} failure:^(NSError *error) {}];
                }) shouldNot] raise];
            });

            it(@"should not require a success block", ^{
                [[theBlock(^{
                    [PCFPushGeofenceUpdater startGeofenceUpdate:engine userInfo:@{} timestamp:0L tags:[NSSet set] success:nil failure:^(NSError *error) {}];
                }) shouldNot] raise];
            });

            it(@"should not require a failure block", ^{
                [[theBlock(^{
                    [PCFPushGeofenceUpdater startGeofenceUpdate:engine userInfo:@{} timestamp:0L tags:[NSSet set] success:^{} failure:nil];
                }) shouldNot] raise];
            });
        });

        context(@"doing updates based on server data", ^{

            __block BOOL wasExpectedResult;
            __block BOOL wasRequestAttempted;

            beforeEach(^{
                engine = [PCFPushGeofenceEngine mock];
                wasExpectedResult = NO;
                wasRequestAttempted = NO;
            });

            afterEach(^{
                [[theValue(wasExpectedResult) should] beYes];
                [[theValue(wasRequestAttempted) should] beYes];
            });

            context(@"bad responses", ^{

                beforeEach(^{
                    [[engine shouldNot] receive:@selector(processResponseData:withTimestamp:withTags:)];
//                    [PCFPushPersistentStorage setServerDeviceID:@"DEVICE_ID"];
                    [[PCFPushGeofenceStatusUtil should] receive:@selector(updateGeofenceStatusWithError:errorReason:number:fileManager:) withArguments:theValue(YES), any(), theValue(97), any(), nil];
                    [PCFPushGeofenceStatusUtil stub:@selector(loadGeofenceStatus:) andReturn:[PCFPushGeofenceStatus statusWithError:NO errorReason:nil number:97]];
                });

                it(@"should handle empty JSON response data", ^{

                    [PCFPushURLConnection stub:@selector(geofenceRequestWithParameters:timestamp:deviceUuid:success:failure:) withBlock:successfulGeofenceRequestStub(200, [NSData data], ^{
                        wasRequestAttempted = YES;
                    })];

                    [PCFPushGeofenceUpdater startGeofenceUpdate:engine userInfo:nil timestamp:7777L tags:[NSSet set] success:^{
                        wasExpectedResult = NO;

                    }                                   failure:^(NSError *error) {
                        wasExpectedResult = YES;
                    }];
                });

                it(@"should handle bogus JSON response data", ^{

                    [PCFPushURLConnection stub:@selector(geofenceRequestWithParameters:timestamp:deviceUuid:success:failure:) withBlock:successfulGeofenceRequestStub(200, [@"I AM NOT JSON" dataUsingEncoding:NSUTF8StringEncoding], ^{
                        wasRequestAttempted = YES;
                    })];

                    [PCFPushGeofenceUpdater startGeofenceUpdate:engine userInfo:nil timestamp:7777L tags:[NSSet set] success:^{
                        wasExpectedResult = NO;

                    }                                   failure:^(NSError *error) {
                        wasExpectedResult = YES;
                    }];
                });

                it(@"should handle a failed request (like a connection error)", ^{

                    [PCFPushURLConnection stub:@selector(geofenceRequestWithParameters:timestamp:deviceUuid:success:failure:) withBlock:failedGeofenceRequestStub(^{
                        wasRequestAttempted = YES;
                    })];

                    [PCFPushGeofenceUpdater startGeofenceUpdate:engine userInfo:nil timestamp:7777L tags:[NSSet set] success:^{
                        wasExpectedResult = NO;

                    }                                   failure:^(NSError *error) {
                        wasExpectedResult = YES;
                    }];
                });
            });

            it(@"should be able to make a successful request", ^{

                NSData *data = [@"{\"last_modified\":123456789123456789}" dataUsingEncoding:NSUTF8StringEncoding];
                [PCFPushURLConnection stub:@selector(geofenceRequestWithParameters:timestamp:deviceUuid:success:failure:) withBlock:successfulGeofenceRequestStub(200, data, ^{
                    wasRequestAttempted = YES;
                })];

                [[PCFPushPersistentStorage should] receive:@selector(setGeofenceLastModifiedTime:) withArguments:theValue(123456789123456789L), nil];
                [[PCFPushGeofenceStatusUtil shouldNot] receive:@selector(updateGeofenceStatusWithError:errorReason:number:fileManager:)];

                PCFPushGeofenceResponseData *expectedResponseData = [[PCFPushGeofenceResponseData alloc] init];
                expectedResponseData.lastModified = 123456789123456789L;
                [[engine should] receive:@selector(processResponseData:withTimestamp:withTags:) withArguments:expectedResponseData, theValue(7777L), [NSSet set], nil];

                [PCFPushGeofenceUpdater startGeofenceUpdate:engine userInfo:nil timestamp:7777L tags:[NSSet set] success:^{
                    wasExpectedResult = YES;

                }                                   failure:^(NSError *error) {
                    wasExpectedResult = NO;
                }];
            });

            it(@"should be able to make a successful request when the userInfo is not null but doesn't contain geofence update JSON", ^{

                NSData *data = [@"{\"last_modified\":123456789123456789}" dataUsingEncoding:NSUTF8StringEncoding];
                [PCFPushURLConnection stub:@selector(geofenceRequestWithParameters:timestamp:deviceUuid:success:failure:) withBlock:successfulGeofenceRequestStub(200, data, ^{
                    wasRequestAttempted = YES;
                })];

                [[PCFPushPersistentStorage should] receive:@selector(setGeofenceLastModifiedTime:) withArguments:theValue(123456789123456789L), nil];
                [[PCFPushGeofenceStatusUtil shouldNot] receive:@selector(updateGeofenceStatusWithError:errorReason:number:fileManager:)];

                PCFPushGeofenceResponseData *expectedResponseData = [[PCFPushGeofenceResponseData alloc] init];
                expectedResponseData.lastModified = 123456789123456789L;
                [[engine should] receive:@selector(processResponseData:withTimestamp:withTags:) withArguments:expectedResponseData, theValue(7777L), [NSSet set], nil];

                NSDictionary *userInfo = @{ @"pivotal.push.something_else" : @"I AM NOT JSON" };

                [PCFPushGeofenceUpdater startGeofenceUpdate:engine userInfo:userInfo timestamp:7777L tags:[NSSet set] success:^{
                    wasExpectedResult = YES;

                }                                   failure:^(NSError *error) {
                    wasExpectedResult = NO;
                }];
            });
        });

        context(@"doing updates based on debug data", ^{

            __block BOOL wasExpectedResult;

            beforeEach(^{
                engine = [PCFPushGeofenceEngine mock];
                wasExpectedResult = NO;
            });

            afterEach(^{
                [[theValue(wasExpectedResult) should] beYes];
            });

            it(@"should read the geofence update from the request data if in debug mode", ^{

                [[PCFPushURLConnection shouldNot] receive:@selector(geofenceRequestWithParameters:timestamp:deviceUuid:success:failure:)];

                [[PCFPushPersistentStorage should] receive:@selector(setGeofenceLastModifiedTime:) withArguments:theValue(123456789123456789L), nil];

                PCFPushGeofenceResponseData *expectedResponseData = [[PCFPushGeofenceResponseData alloc] init];
                expectedResponseData.lastModified = 123456789123456789L;
                [[engine should] receive:@selector(processResponseData:withTimestamp:withTags:) withArguments:expectedResponseData, theValue(7777L), [NSSet set], nil];

                NSDictionary *userInfo = @{ @"pivotal.push.geofence_update_json" : @"{\"last_modified\":123456789123456789}" };

                [PCFPushGeofenceUpdater startGeofenceUpdate:engine userInfo:userInfo timestamp:7777L tags:[NSSet set] success:^{
                    wasExpectedResult = YES;

                }                                   failure:^(NSError *error) {
                    wasExpectedResult = NO;
                }];
            });

            it(@"should handle bad geofence update data in the request data if in debug mode", ^{

                [[PCFPushURLConnection shouldNot] receive:@selector(geofenceRequestWithParameters:timestamp:deviceUuid:success:failure:)];

                [[PCFPushPersistentStorage shouldNot] receive:@selector(setGeofenceLastModifiedTime:)];

                [[engine shouldNot] receive:@selector(processResponseData:withTimestamp:withTags:)];

                NSDictionary *userInfo = @{ @"pivotal.push.geofence_update_json" : @"I AM NOT JSON" };

                [PCFPushGeofenceUpdater startGeofenceUpdate:engine userInfo:userInfo timestamp:7777L tags:[NSSet set] success:^{
                    wasExpectedResult = NO;

                }                                   failure:^(NSError *error) {
                    wasExpectedResult = YES;
                }];
            });
        });
    });

SPEC_END