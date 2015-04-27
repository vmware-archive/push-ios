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
                [engine stub:@selector(processResponseData:withTimestamp:)];
            });

            it(@"should require a geofence engine", ^{
                [[theBlock(^{
                    [PCFPushGeofenceUpdater startGeofenceUpdate:nil userInfo:@{} timestamp:0L success:^{} failure:^(NSError *error){}];
                }) should] raise];
            });

            it(@"should not require a userdata object", ^{
                [[theBlock(^{
                    [PCFPushGeofenceUpdater startGeofenceUpdate:engine userInfo:nil timestamp:0L success:^{} failure:^(NSError *error){}];
                }) shouldNot] raise];
            });

            it(@"should not require a success block", ^{
                [[theBlock(^{
                    [PCFPushGeofenceUpdater startGeofenceUpdate:engine userInfo:@{} timestamp:0L success:nil failure:^(NSError *error){}];
                }) shouldNot] raise];
            });

            it(@"should not require a failure block", ^{
                [[theBlock(^{
                    [PCFPushGeofenceUpdater startGeofenceUpdate:engine userInfo:@{} timestamp:0L success:^{} failure:nil];
                }) shouldNot] raise];
            });
        });

        context(@"doing updates based on server data", ^{

            __block BOOL wasExpectedResult;
            __block BOOL wasRequestMade;

            beforeEach(^{
                engine = [PCFPushGeofenceEngine mock];
                wasExpectedResult = NO;
                wasRequestMade = NO;
            });

            afterEach(^{
                [[theValue(wasExpectedResult) shouldEventually] beYes];
                [[theValue(wasRequestMade) shouldEventually] beYes];
            });

            context(@"bad responses", ^{

                afterEach(^{
                    [[engine shouldNotEventually] receive:@selector(processResponseData:withTimestamp:)];
                });

                it(@"should handle empty JSON response data", ^{

                    [PCFPushURLConnection stub:@selector(geofenceRequestWithParameters:timestamp:success:failure:) withBlock:^id(NSArray *params) {
                        wasRequestMade = YES;
                        NSData *data = [NSData data];
                        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200 HTTPVersion:nil headerFields:nil];
                        void(^completionHandler)(NSURLResponse *, NSData *) = params[2];
                        completionHandler(response, data);
                        return nil;
                    }];

                    [PCFPushGeofenceUpdater startGeofenceUpdate:engine userInfo:nil timestamp:7777L success:^{
                        wasExpectedResult = NO;

                    }                    failure:^(NSError *error) {
                        wasExpectedResult = YES;
                    }];
                });

                it(@"should handle bogus JSON response data", ^{

                    [PCFPushURLConnection stub:@selector(geofenceRequestWithParameters:timestamp:success:failure:) withBlock:^id(NSArray *params) {
                        wasRequestMade = YES;
                        NSData *data = [@"I AM NOT JSON" dataUsingEncoding:NSUTF8StringEncoding];
                        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200 HTTPVersion:nil headerFields:nil];
                        void(^completionHandler)(NSURLResponse *, NSData *) = params[2];
                        completionHandler(response, data);
                        return nil;
                    }];

                    [PCFPushGeofenceUpdater startGeofenceUpdate:engine userInfo:nil timestamp:7777L success:^{
                        wasExpectedResult = NO;

                    }                    failure:^(NSError *error) {
                        wasExpectedResult = YES;
                    }];
                });

                it(@"should handle a failed reponse status", ^{

                    [PCFPushURLConnection stub:@selector(geofenceRequestWithParameters:timestamp:success:failure:) withBlock:^id(NSArray *params) {
                        wasRequestMade = YES;
                        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:400 HTTPVersion:nil headerFields:nil];
                        void(^completionHandler)(NSURLResponse *, NSData *) = params[2];
                        completionHandler(response, nil);
                        return nil;
                    }];

                    [PCFPushGeofenceUpdater startGeofenceUpdate:engine userInfo:nil timestamp:7777L success:^{
                        wasExpectedResult = NO;

                    }                    failure:^(NSError *error) {
                        wasExpectedResult = YES;
                    }];
                });

                it(@"should handle a failed request (like a connection error)", ^{

                    [PCFPushURLConnection stub:@selector(geofenceRequestWithParameters:timestamp:success:failure:) withBlock:^id(NSArray *params) {
                        wasRequestMade = YES;
                        NSError *error = [[NSError alloc] init];
                        void(^completionHandler)(NSError *) = params[3];
                        completionHandler(error);
                        return nil;
                    }];

                    [PCFPushGeofenceUpdater startGeofenceUpdate:engine userInfo:nil timestamp:7777L success:^{
                        wasExpectedResult = NO;

                    }                    failure:^(NSError *error) {
                        wasExpectedResult = YES;
                    }];
                });
            });

            it(@"should be able to make a successful request", ^{

                [PCFPushURLConnection stub:@selector(geofenceRequestWithParameters:timestamp:success:failure:) withBlock:^id(NSArray *params) {
                    wasRequestMade = YES;
                    NSData *data = [@"{\"last_modified\":123456789123456789}" dataUsingEncoding:NSUTF8StringEncoding];
                    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200 HTTPVersion:nil headerFields:nil];
                    void(^completionHandler)(NSURLResponse *, NSData *) = params[2];
                    completionHandler(response, data);
                    return nil;
                }];

                [[PCFPushPersistentStorage should] receive:@selector(setGeofenceLastModifiedTime:) withArguments:theValue(123456789123456789L), nil];

                PCFPushGeofenceResponseData *expectedResponseData = [[PCFPushGeofenceResponseData alloc] init];
                expectedResponseData.lastModified = 123456789123456789L;
                [[engine shouldEventually] receive:@selector(processResponseData:withTimestamp:) withArguments:expectedResponseData, theValue(7777L), nil];

                [PCFPushGeofenceUpdater startGeofenceUpdate:engine userInfo:nil timestamp:7777L success:^{
                    wasExpectedResult = YES;

                }                    failure:^(NSError *error) {
                    wasExpectedResult = NO;
                }];
            });

            it(@"should be able to make a successful request when the userInfo is not null but doesn't contain geofence update JSON", ^{

                [PCFPushURLConnection stub:@selector(geofenceRequestWithParameters:timestamp:success:failure:) withBlock:^id(NSArray *params) {
                    wasRequestMade = YES;
                    NSData *data = [@"{\"last_modified\":123456789123456789}" dataUsingEncoding:NSUTF8StringEncoding];
                    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200 HTTPVersion:nil headerFields:nil];
                    void(^completionHandler)(NSURLResponse *, NSData *) = params[2];
                    completionHandler(response, data);
                    return nil;
                }];

                [[PCFPushPersistentStorage should] receive:@selector(setGeofenceLastModifiedTime:) withArguments:theValue(123456789123456789L), nil];

                PCFPushGeofenceResponseData *expectedResponseData = [[PCFPushGeofenceResponseData alloc] init];
                expectedResponseData.lastModified = 123456789123456789L;
                [[engine shouldEventually] receive:@selector(processResponseData:withTimestamp:) withArguments:expectedResponseData, theValue(7777L), nil];

                NSDictionary *userInfo = @{ @"pivotal.push.something_else" : @"I AM NOT JSON" };

                [PCFPushGeofenceUpdater startGeofenceUpdate:engine userInfo:userInfo timestamp:7777L success:^{
                    wasExpectedResult = YES;

                } failure:^(NSError *error) {
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
                [[theValue(wasExpectedResult) shouldEventually] beYes];
            });

            it(@"should read the geofence update from the request data if in debug mode", ^{

                [[PCFPushURLConnection shouldNot] receive:@selector(geofenceRequestWithParameters:timestamp:success:failure:)];

                [[PCFPushPersistentStorage should] receive:@selector(setGeofenceLastModifiedTime:) withArguments:theValue(123456789123456789L), nil];

                PCFPushGeofenceResponseData *expectedResponseData = [[PCFPushGeofenceResponseData alloc] init];
                expectedResponseData.lastModified = 123456789123456789L;
                [[engine shouldEventually] receive:@selector(processResponseData:withTimestamp:) withArguments:expectedResponseData, theValue(7777L), nil];

                NSDictionary *userInfo = @{ @"pivotal.push.geofence_update_json" : @"{\"last_modified\":123456789123456789}" };

                [PCFPushGeofenceUpdater startGeofenceUpdate:engine userInfo:userInfo timestamp:7777L success:^{
                    wasExpectedResult = YES;

                } failure:^(NSError *error) {
                    wasExpectedResult = NO;
                }];
            });

            it(@"should handle bad geofence update data in the request data if in debug mode", ^{

                [[PCFPushURLConnection shouldNot] receive:@selector(geofenceRequestWithParameters:timestamp:success:failure:)];

                [[PCFPushPersistentStorage shouldNot] receive:@selector(setGeofenceLastModifiedTime:)];

                [[engine shouldNotEventually] receive:@selector(processResponseData:withTimestamp:)];

                NSDictionary *userInfo = @{ @"pivotal.push.geofence_update_json" : @"I AM NOT JSON" };

                [PCFPushGeofenceUpdater startGeofenceUpdate:engine userInfo:userInfo timestamp:7777L success:^{
                    wasExpectedResult = NO;

                } failure:^(NSError *error) {
                    wasExpectedResult = YES;
                }];
            });
        });
    });

SPEC_END