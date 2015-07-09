//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "Kiwi.h"
#import "PCFPush.h"
#import "PCFPushErrors.h"
#import "PCFPushParameters.h"
#import "PCFPushClientTest.h"
#import "PCFPushSpecsHelper.h"
#import "NSObject+PCFJSONizable.h"
#import "PCFPushGeofenceUpdater.h"
#import "PCFPushGeofenceHandler.h"
#import "PCFPushPersistentStorage.h"
#import "PCFPushGeofenceStatusUtil.h"
#import "PCFPushRegistrationPutRequestData.h"
#import "PCFPushRegistrationPostRequestData.h"
#import "NSURLConnection+PCFBackEndConnection.h"

SPEC_BEGIN(PCFPushSpecs)


describe(@"PCFPush", ^{
    __block PCFPushSpecsHelper *helper = nil;

    beforeEach(^{
        [PCFPushClient resetSharedClient];
        helper = [[PCFPushSpecsHelper alloc] init];
        [helper setupParameters];
    });

    afterEach(^{
        [helper reset];
    });

    describe(@"setting parameters", ^{

        describe(@"empty and nillable parameters", ^{

            __block BOOL succeeded = NO;
            __block void (^successBlock)() = ^{
                succeeded = YES;
            };
            __block void (^failureBlock)(NSError *) = ^(NSError *error) {
                fail(@"should have succeeded");
            };

            beforeEach(^{
                [helper setupDefaultPLIST];
                [helper setupSuccessfulAsyncRequest];
                [PCFPushGeofenceStatusUtil stub:@selector(updateGeofenceStatusWithError:errorReason:number:fileManager:)];
            });

            afterEach(^{
                [[theValue(succeeded) shouldEventually] equal:theValue(YES)];
            });

            it(@"should accept a nil deviceAlias", ^{
                [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:helper.tags1 deviceAlias:nil success:successBlock failure:failureBlock];
            });

            it(@"should accept an empty deviceAlias", ^{
                [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:helper.tags1 deviceAlias:@"" success:successBlock failure:failureBlock];
            });

            it(@"should accept a non-empty deviceAlias and tags", ^{
                [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:helper.tags1 deviceAlias:@"NOT EMPTY" success:successBlock failure:failureBlock];
            });

            it(@"should accept a nil tags", ^{
                [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:nil deviceAlias:@"NOT EMPTY" success:successBlock failure:failureBlock];
            });

            it(@"should accept an empty tags", ^{
                [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:[NSSet set] deviceAlias:@"NOT EMPTY" success:successBlock failure:failureBlock];
            });

            it(@"should accept a nil deviceAlias and nil tags", ^{
                [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:nil deviceAlias:nil success:successBlock failure:failureBlock];
            });

            it(@"should accept an empty deviceAlias and empty tags", ^{
                [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:[NSSet set] deviceAlias:@"" success:successBlock failure:failureBlock];
            });
        });

        describe(@"nil callbacks", ^{

            void (^successBlock)() = ^{};
            void (^failureBlock)(NSError *) = ^(NSError *error) {};

            beforeEach(^{
                [helper setupDefaultPLIST];
                [helper setupSuccessfulAsyncRequest];
                [PCFPushGeofenceStatusUtil stub:@selector(updateGeofenceStatusWithError:errorReason:number:fileManager:)];
            });

            it(@"should accept a nil failureBlock", ^{
                [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:[NSSet set] deviceAlias:@"NOT EMPTY" success:successBlock failure:nil];
            });

            it(@"should accept a nil successBlock", ^{
                [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:[NSSet set] deviceAlias:@"NOT EMPTY" success:nil failure:failureBlock];
            });
        });

        it(@"should raise an exception if parameters are nil", ^{
            [[theBlock(^{
                [helper setupDefaultPLISTWithFile:@"PCFPushParameters-Empty"];
                [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:nil deviceAlias:nil success:nil failure:nil];
            }) should] raiseWithName:NSInvalidArgumentException];
        });

        it(@"should raise an exception if parameters are invalid", ^{
            [[theBlock(^{
                [helper setupDefaultPLISTWithFile:@"PCFPushParameters-Invalid"];
                [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:nil deviceAlias:nil success:nil failure:nil];
            }) should] raiseWithName:NSInvalidArgumentException];
        });

        it(@"should raise an exception if startRegistration is called without parameters being set", ^{
            [[theBlock(^{
                [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:nil deviceAlias:nil success:nil failure:nil];
            }) should] raiseWithName:NSInvalidArgumentException];
        });

        it(@"should raise an exception if the APNS device token is nil", ^{
            [[theBlock(^{
                [PCFPush registerForPCFPushNotificationsWithDeviceToken:nil tags:[NSSet set] deviceAlias:@"NOT EMPTY" success:nil failure:nil];
            }) should] raiseWithName:NSInvalidArgumentException];
        });

        it(@"should raise an exception if the APNS device token is empty", ^{
            [[theBlock(^{
                [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:[NSSet set] deviceAlias:@"NOT EMPTY" success:nil failure:nil];
            }) should] raiseWithName:NSInvalidArgumentException];
        });
    });

    describe(@"a push registration with an existing registration", ^{

        __block NSInteger successCount;
        __block NSInteger updateRegistrationCount;
        __block void (^testBlock)(SEL, id, NSString*);
        __block NSSet *expectedSubscribeTags;
        __block NSSet *expectedUnsubscribeTags;

        beforeEach(^{
            successCount = 0;
            updateRegistrationCount = 0;
            expectedSubscribeTags = nil;
            expectedUnsubscribeTags = nil;

            testBlock = ^(SEL sel, id newPersistedValue, NSString *expectedHttpMethod) {

                [helper setupSuccessfulAsyncRequestWithBlock:^(NSURLRequest *request) {

                    [[request.HTTPMethod should] equal:expectedHttpMethod];

                    updateRegistrationCount++;

                    NSError *error;

                    PCFPushRegistrationData *requestBody;

                    if ([expectedHttpMethod isEqualToString:@"PUT"]) {

                        PCFPushRegistrationPutRequestData *requestPutBody = [PCFPushRegistrationPutRequestData pcfPushFromJSONData:request.HTTPBody error:&error];
                        requestBody = requestPutBody;

                        [[error should] beNil];
                        [[requestPutBody shouldNot] beNil];

                        if (expectedSubscribeTags) {
                            [[[NSSet setWithArray:requestPutBody.subscribeTags] should] equal:expectedSubscribeTags];
                        } else {
                            [[requestPutBody.subscribeTags should] beNil];
                        }

                        if (expectedUnsubscribeTags) {
                            [[[NSSet setWithArray:requestPutBody.unsubscribeTags] should] equal:expectedUnsubscribeTags];
                        } else {
                            [[requestPutBody.unsubscribeTags should] beNil];
                        }

                    } else if ([expectedHttpMethod isEqualToString:@"POST"]) {

                        PCFPushRegistrationPostRequestData *requestPostBody = [PCFPushRegistrationPostRequestData pcfPushFromJSONData:request.HTTPBody error:&error];
                        requestBody = requestPostBody;

                        [[error should] beNil];
                        [[requestPostBody shouldNot] beNil];

                        if (expectedSubscribeTags) {
                            [[[NSSet setWithArray:requestPostBody.tags] should] equal:expectedSubscribeTags];
                        } else {
                            [[requestPostBody.tags should] beNil];
                        }
                    }

                    [[requestBody shouldNot] beNil];
                    [[requestBody.variantUUID should] beNil];
                    [[requestBody.deviceAlias should] equal:TEST_DEVICE_ALIAS_1];
                }];

                [[NSURLConnection shouldEventually] receive:@selector(pcfPushSendAsynchronousRequestWrapper:queue:completionHandler:)];

                [helper setupDefaultPersistedParameters];
                [helper setupDefaultPLIST];

                [PCFPushPersistentStorage performSelector:sel withObject:newPersistedValue];

                void (^successBlock)() = ^{
                    successCount++;
                };

                void (^failureBlock)(NSError *) = ^(NSError *error) {
                    fail(@"registration failure block executed");
                };

                [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:helper.params.pushTags deviceAlias:helper.params.pushDeviceAlias success:successBlock failure:failureBlock];
            };
        });

        afterEach(^{
            [[theValue(successCount) shouldEventually] equal:theValue(1)];
            [[theValue(updateRegistrationCount) shouldEventually] equal:theValue(1)];
        });

        context(@"with no geofence update in the past (i.e.: geofences have been disabled)", ^{

            context(@"geofences are enabled (and so will update geofences this time)", ^{

                beforeEach(^{
                    [helper setupGeofencesForSuccessfulUpdateWithLastModifiedTime:1337L];
                    [[PCFPushGeofenceUpdater should] receive:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:) withCount:1];
                    [[PCFPushGeofenceUpdater shouldNot] receive:@selector(clearAllGeofences:)];
                    [[PCFPushGeofenceHandler shouldNot] receive:@selector(reregisterGeofencesWithEngine:subscribedTags:)];
                });

                afterEach(^{
                    [[theValue([PCFPushPersistentStorage lastGeofencesModifiedTime]) should] equal:theValue(1337L)];
                });

                it(@"should do a new push registration and geofences after the variantUuid changes", ^{
                    expectedSubscribeTags = helper.tags1;
                    testBlock(@selector(setVariantUUID:), @"DIFFERENT STRING", @"POST");
                });

                it(@"should do a new push registration and geofences after the variantUuid is initially set", ^{
                    expectedSubscribeTags = helper.tags1;
                    testBlock(@selector(setVariantUUID:), nil, @"POST");
                });

                it(@"should do a new push registration and geofences after the variantSecret changes", ^{
                    expectedSubscribeTags = helper.tags1;
                    testBlock(@selector(setVariantSecret:), @"DIFFERENT STRING", @"POST");
                });

                it(@"should do a new push registration and geofences after the variantSecret is initially set", ^{
                    expectedSubscribeTags = helper.tags1;
                    testBlock(@selector(setVariantSecret:), nil, @"POST");
                });

                it(@"should update the push registration and geofences after the deviceAlias changes (with geofence update)", ^{
                    testBlock(@selector(setDeviceAlias:), @"DIFFERENT STRING", @"PUT");
                });

                it(@"should update the push registration and geofences after the deviceAlias is initially set (with geofence update)", ^{
                    testBlock(@selector(setDeviceAlias:), nil, @"PUT");
                });

                it(@"should update the push registration and geofences after the APNSDeviceToken changes", ^{
                    testBlock(@selector(setAPNSDeviceToken:), [@"DIFFERENT TOKEN" dataUsingEncoding:NSUTF8StringEncoding], @"PUT");
                });

                it(@"should update the push registration and geofences after the tags change to a different value", ^{
                    expectedSubscribeTags = helper.tags1;
                    expectedUnsubscribeTags = [NSSet setWithArray:@[@"DIFFERENT TAG"]];
                    testBlock(@selector(setTags:), expectedUnsubscribeTags, @"PUT");
                });

                it(@"should update the push registration and geofences after tags initially set from nil", ^{
                    expectedSubscribeTags = helper.tags1;
                    testBlock(@selector(setTags:), nil, @"PUT");
                });

                it(@"should update the push registration and geofences after tags initially set from empty", ^{
                    expectedSubscribeTags = helper.tags1;
                    testBlock(@selector(setTags:), [NSSet set], @"PUT");
                });

                it(@"should update the push registration and geofences after tags change to nil", ^{
                    helper.params.pushTags = nil;
                    expectedUnsubscribeTags = helper.tags1;
                    testBlock(@selector(setTags:), helper.tags1, @"PUT");
                });

                it(@"should update the push registration and geofences after tags change to empty", ^{
                    helper.params.pushTags = [NSSet set];
                    expectedUnsubscribeTags = helper.tags1;
                    testBlock(@selector(setTags:), helper.tags1, @"PUT");
                });
            });

            context(@"geofences are disabled (neither clear nor update geofences)", ^{

                beforeEach(^{
                    [helper setupDefaultPLISTWithFile:@"Pivotal-GeofencesDisabled"];
                    [[PCFPushGeofenceUpdater shouldNot] receive:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:)];
                    [[PCFPushGeofenceUpdater shouldNot] receive:@selector(clearAllGeofences:)];
                    [[PCFPushGeofenceHandler shouldNot] receive:@selector(reregisterGeofencesWithEngine:subscribedTags:)];
                });

                afterEach(^{
                    [[theValue([PCFPushPersistentStorage lastGeofencesModifiedTime]) should] equal:theValue(PCF_NEVER_UPDATED_GEOFENCES)];
                });

                it(@"should do a new push registration and geofences after the variantUuid changes", ^{
                    expectedSubscribeTags = helper.tags1;
                    testBlock(@selector(setVariantUUID:), @"DIFFERENT STRING", @"POST");
                });

                it(@"should do a new push registration and geofences after the variantUuid is initially set", ^{
                    expectedSubscribeTags = helper.tags1;
                    testBlock(@selector(setVariantUUID:), nil, @"POST");
                });

                it(@"should do a new push registration and geofences after the variantSecret changes", ^{
                    expectedSubscribeTags = helper.tags1;
                    testBlock(@selector(setVariantSecret:), @"DIFFERENT STRING", @"POST");
                });

                it(@"should do a new push registration and geofences after the variantSecret is initially set", ^{
                    expectedSubscribeTags = helper.tags1;
                    testBlock(@selector(setVariantSecret:), nil, @"POST");
                });

                it(@"should update the push registration and geofences after the deviceAlias changes (with geofence update)", ^{
                    testBlock(@selector(setDeviceAlias:), @"DIFFERENT STRING", @"PUT");
                });

                it(@"should update the push registration and geofences after the deviceAlias is initially set (with geofence update)", ^{
                    testBlock(@selector(setDeviceAlias:), nil, @"PUT");
                });

                it(@"should update the push registration and geofences after the APNSDeviceToken changes", ^{
                    testBlock(@selector(setAPNSDeviceToken:), [@"DIFFERENT TOKEN" dataUsingEncoding:NSUTF8StringEncoding], @"PUT");
                });

                it(@"should update the push registration and geofences after the tags change to a different value", ^{
                    expectedSubscribeTags = helper.tags1;
                    expectedUnsubscribeTags = [NSSet setWithArray:@[@"DIFFERENT TAG"]];
                    testBlock(@selector(setTags:), expectedUnsubscribeTags, @"PUT");
                });

                it(@"should update the push registration and geofences after tags initially set from nil", ^{
                    expectedSubscribeTags = helper.tags1;
                    testBlock(@selector(setTags:), nil, @"PUT");
                });

                it(@"should update the push registration and geofences after tags initially set from empty", ^{
                    expectedSubscribeTags = helper.tags1;
                    testBlock(@selector(setTags:), [NSSet set], @"PUT");
                });

                it(@"should update the push registration and geofences after tags change to nil", ^{
                    helper.params.pushTags = nil;
                    expectedUnsubscribeTags = helper.tags1;
                    testBlock(@selector(setTags:), helper.tags1, @"PUT");
                });

                it(@"should update the push registration and geofences after tags change to empty", ^{
                    helper.params.pushTags = [NSSet set];
                    expectedUnsubscribeTags = helper.tags1;
                    testBlock(@selector(setTags:), helper.tags1, @"PUT");
                });
            });
        });

        context(@"with geofences updated in the past (same variant)", ^{

            context(@"geofences are enabled (and so will skip a geofence update this time)", ^{

                beforeEach(^{
                    [PCFPushPersistentStorage setGeofenceLastModifiedTime:1337L];
                    [[PCFPushGeofenceUpdater shouldNot] receive:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:)];
                    [[PCFPushGeofenceUpdater shouldNot] receive:@selector(clearAllGeofences:)];
                });

                afterEach(^{
                    [[theValue([PCFPushPersistentStorage lastGeofencesModifiedTime]) should] equal:theValue(1337L)];
                });

                context(@"tags the same", ^{

                    beforeEach(^{
                        [[PCFPushGeofenceHandler shouldNot] receive:@selector(reregisterGeofencesWithEngine:subscribedTags:)];
                    });

                    it(@"should update the push registration after the deviceAlias changes (without geofence update)", ^{
                        testBlock(@selector(setDeviceAlias:), @"DIFFERENT STRING", @"PUT");
                    });

                    it(@"should update the push registration after the deviceAlias is initially set (without geofence update)", ^{
                        testBlock(@selector(setDeviceAlias:), nil, @"PUT");
                    });

                    it(@"should update the push registration after the APNSDeviceToken changes", ^{
                        testBlock(@selector(setAPNSDeviceToken:), [@"DIFFERENT TOKEN" dataUsingEncoding:NSUTF8StringEncoding], @"PUT");
                    });
                });

                context(@"tags different", ^{

                    beforeEach(^{
                        [[PCFPushGeofenceHandler should] receive:@selector(reregisterGeofencesWithEngine:subscribedTags:)];
                    });

                    it(@"should update the push registration after the tags change to a different value", ^{
                        expectedSubscribeTags = helper.tags1;
                        expectedUnsubscribeTags = [NSSet setWithArray:@[@"DIFFERENT TAG"]];
                        testBlock(@selector(setTags:), expectedUnsubscribeTags, @"PUT");
                    });

                    it(@"should update the push registration after tags initially set from nil", ^{
                        expectedSubscribeTags = helper.tags1;
                        testBlock(@selector(setTags:), nil, @"PUT");
                    });

                    it(@"should update the push registration after tags initially set from empty", ^{
                        expectedSubscribeTags = helper.tags1;
                        testBlock(@selector(setTags:), [NSSet set], @"PUT");
                    });

                    it(@"should update the push registration after tags change to nil", ^{
                        helper.params.pushTags = nil;
                        expectedUnsubscribeTags = helper.tags1;
                        testBlock(@selector(setTags:), helper.tags1, @"PUT");
                    });

                    it(@"should update the push registration after tags change to empty", ^{
                        helper.params.pushTags = [NSSet set];
                        expectedUnsubscribeTags = helper.tags1;
                        testBlock(@selector(setTags:), helper.tags1, @"PUT");
                    });
                });
            });

            context(@"geofences are disabled (so it should clear geofences this time)", ^{

                beforeEach(^{
                    [helper setupDefaultPLISTWithFile:@"Pivotal-GeofencesDisabled"];
                    [PCFPushPersistentStorage setGeofenceLastModifiedTime:1337L];
                    [[PCFPushGeofenceHandler shouldNot] receive:@selector(reregisterGeofencesWithEngine:subscribedTags:)];
                    [[PCFPushGeofenceUpdater shouldNot] receive:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:)];
                    [[PCFPushGeofenceUpdater should] receive:@selector(clearAllGeofences:)];
                    [PCFPushGeofenceUpdater stub:@selector(clearAllGeofences:) withBlock:^id(NSArray *params) {
                        [PCFPushPersistentStorage setGeofenceLastModifiedTime:PCF_NEVER_UPDATED_GEOFENCES];
                        return nil;
                    }];
                });

                afterEach(^{
                    [[theValue([PCFPushPersistentStorage lastGeofencesModifiedTime]) should] equal:theValue(PCF_NEVER_UPDATED_GEOFENCES)];
                });

                it(@"should update the push registration after the deviceAlias changes (without geofence update)", ^{
                    testBlock(@selector(setDeviceAlias:), @"DIFFERENT STRING", @"PUT");
                });

                it(@"should update the push registration after the deviceAlias is initially set (without geofence update)", ^{
                    testBlock(@selector(setDeviceAlias:), nil, @"PUT");
                });

                it(@"should update the push registration after the APNSDeviceToken changes", ^{
                    testBlock(@selector(setAPNSDeviceToken:), [@"DIFFERENT TOKEN" dataUsingEncoding:NSUTF8StringEncoding], @"PUT");
                });

                it(@"should update the push registration after the tags change to a different value", ^{
                    expectedSubscribeTags = helper.tags1;
                    expectedUnsubscribeTags = [NSSet setWithArray:@[@"DIFFERENT TAG"]];
                    testBlock(@selector(setTags:), expectedUnsubscribeTags, @"PUT");
                });

                it(@"should update the push registration after tags initially set from nil", ^{
                    expectedSubscribeTags = helper.tags1;
                    testBlock(@selector(setTags:), nil, @"PUT");
                });

                it(@"should update the push registration after tags initially set from empty", ^{
                    expectedSubscribeTags = helper.tags1;
                    testBlock(@selector(setTags:), [NSSet set], @"PUT");
                });

                it(@"should update the push registration after tags change to nil", ^{
                    helper.params.pushTags = nil;
                    expectedUnsubscribeTags = helper.tags1;
                    testBlock(@selector(setTags:), helper.tags1, @"PUT");
                });

                it(@"should update the push registration after tags change to empty", ^{
                    helper.params.pushTags = [NSSet set];
                    expectedUnsubscribeTags = helper.tags1;
                    testBlock(@selector(setTags:), helper.tags1, @"PUT");
                });
            });
        });

        context(@"with geofences updated in the past (different variant)", ^{

            context(@"with geofences enabled (and will still do a geofence reset and update this time)", ^{

                beforeEach(^{
                    expectedSubscribeTags = helper.tags1;
                    [PCFPushPersistentStorage setGeofenceLastModifiedTime:1337L];
                    [helper setupClearGeofencesForSuccess];
                    [helper setupGeofencesForSuccessfulUpdateWithLastModifiedTime:2784L];
                    [[PCFPushGeofenceUpdater should] receive:@selector(clearAllGeofences:) withCount:1];
                    [[PCFPushGeofenceUpdater should] receive:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:) withCount:1];
                    [[PCFPushGeofenceHandler shouldNot] receive:@selector(reregisterGeofencesWithEngine:subscribedTags:)];
                });

                afterEach(^{
                    [[theValue([PCFPushPersistentStorage lastGeofencesModifiedTime]) should] equal:theValue(2784L)];
                });

                it(@"should do a new push registration and geofences after the variantUuid changes", ^{
                    testBlock(@selector(setVariantUUID:), @"DIFFERENT STRING", @"POST");
                });

                it(@"should do a new push registration and geofences after the variantUuid is initially set", ^{
                    testBlock(@selector(setVariantUUID:), nil, @"POST");
                });

                it(@"should do a new push registration and geofences after the variantSecret changes", ^{
                    testBlock(@selector(setVariantSecret:), @"DIFFERENT STRING", @"POST");
                });

                it(@"should do a new push registration and geofences after the variantSecret is initially set", ^{
                    testBlock(@selector(setVariantSecret:), nil, @"POST");
                });
            });

            context(@"with geofences disabled (and will just do a geofence reset - with no update)", ^{

                beforeEach(^{
                    expectedSubscribeTags = helper.tags1;
                    [helper setupDefaultPLISTWithFile:@"Pivotal-GeofencesDisabled"];
                    [PCFPushPersistentStorage setGeofenceLastModifiedTime:1337L];
                    [helper setupClearGeofencesForSuccess];
                    [[PCFPushGeofenceHandler shouldNot] receive:@selector(reregisterGeofencesWithEngine:subscribedTags:)];
                    [[PCFPushGeofenceUpdater should] receive:@selector(clearAllGeofences:) withCount:1];
                    [[PCFPushGeofenceUpdater shouldNot] receive:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:)];
                    [PCFPushGeofenceUpdater stub:@selector(clearAllGeofences:) withBlock:^id(NSArray *params) {
                        [PCFPushPersistentStorage setGeofenceLastModifiedTime:PCF_NEVER_UPDATED_GEOFENCES];
                        return nil;
                    }];
                });

                afterEach(^{
                    [[theValue([PCFPushPersistentStorage lastGeofencesModifiedTime]) should] equal:theValue(PCF_NEVER_UPDATED_GEOFENCES)];
                });

                it(@"should do a new push registration and geofences after the variantUuid changes", ^{
                    testBlock(@selector(setVariantUUID:), @"DIFFERENT STRING", @"POST");
                });

                it(@"should do a new push registration and geofences after the variantUuid is initially set", ^{
                    testBlock(@selector(setVariantUUID:), nil, @"POST");
                });

                it(@"should do a new push registration and geofences after the variantSecret changes", ^{
                    testBlock(@selector(setVariantSecret:), @"DIFFERENT STRING", @"POST");
                });

                it(@"should do a new push registration and geofences after the variantSecret is initially set", ^{
                    testBlock(@selector(setVariantSecret:), nil, @"POST");
                });
            });
        });
    });

    describe(@"successful push registration", ^{

        context(@"geofences enabled", ^{
            it(@"should make a POST request to the server and update geofences on a new registration", ^{

                __block BOOL wasSuccessBlockExecuted = NO;
                __block NSSet *expectedTags = helper.tags1;

                [helper setupGeofencesForSuccessfulUpdateWithLastModifiedTime:999L withBlock:^void(NSArray *params) {
                    int64_t timestamp = [params[2] longLongValue];
                    [[theValue(timestamp) should] beZero];
                }];
                [[PCFPushGeofenceUpdater should] receive:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:) withCount:1];

                [[NSURLConnection shouldEventually] receive:@selector(pcfPushSendAsynchronousRequestWrapper:queue:completionHandler:) withCount:1];

                [helper setupSuccessfulAsyncRequestWithBlock:^(NSURLRequest *request) {

                    [[request.HTTPMethod should] equal:@"POST"];

                    NSError *error;
                    PCFPushRegistrationPostRequestData *requestBody = [PCFPushRegistrationPostRequestData pcfPushFromJSONData:request.HTTPBody error:&error];
                    [[error should] beNil];
                    [[requestBody shouldNot] beNil];
                    [[[NSSet setWithArray:requestBody.tags] should] equal:expectedTags];
                }];

                [helper setupDefaultPLIST];

                void (^successBlock)() = ^{
                    wasSuccessBlockExecuted = YES;
                };

                void (^failureBlock)(NSError *) = ^(NSError *error) {
                    fail(@"registration failure block executed");
                };

                [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:helper.tags1 deviceAlias:TEST_DEVICE_ALIAS success:successBlock failure:failureBlock];

                [[theValue(wasSuccessBlockExecuted) shouldEventually] beTrue];
            });

            context(@"should bypass registering against Remote Push Server if Device Token matches the stored token.", ^{

                __block NSInteger registrationRequestCount;
                __block NSInteger geofenceUpdateCount;
                __block BOOL wasSuccessBlockExecuted;
                __block BOOL wasFailBlockExecuted;
                __block void (^successBlock)() = ^{
                    wasSuccessBlockExecuted = YES;
                };
                __block void (^failureBlock)(NSError *) = ^(NSError *error) {
                    wasFailBlockExecuted = YES;
                };

                beforeEach(^{
                    registrationRequestCount = 0;
                    geofenceUpdateCount = 0;
                    wasSuccessBlockExecuted = NO;
                    wasFailBlockExecuted = NO;
                });

                afterEach(^{
                    [[NSURLConnection shouldEventually] receive:@selector(sendAsynchronousRequest:queue:completionHandler:) withCount:1];
                });

                it(@"when geofences were never updated (and the geofence update passes)", ^{

                    [helper setupSuccessfulAsyncRequestWithBlock:^(NSURLRequest *request) {
                        registrationRequestCount += 1;
                    }];

                    [helper setupGeofencesForSuccessfulUpdateWithLastModifiedTime:1337L withBlock:^(NSArray *array) {
                        geofenceUpdateCount += 1;
                    }];

                    [PCFPush load];
                    [helper setupDefaultPLIST];

                    [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:helper.tags1 deviceAlias:TEST_DEVICE_ALIAS success:nil failure:failureBlock];
                    [[theValue(registrationRequestCount) should] equal:theValue(1)];
                    [[theValue(geofenceUpdateCount) should] equal:theValue(1)];
                    [PCFPush load]; // Reset the state in the state engine

                    [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:helper.tags1 deviceAlias:TEST_DEVICE_ALIAS success:successBlock failure:failureBlock];
                    [[theValue(registrationRequestCount) should] equal:theValue(1)]; // Shows that the second registration request was a no-op
                    [[theValue(geofenceUpdateCount) should] equal:theValue(1)];
                    [[theValue(wasSuccessBlockExecuted) shouldEventually] beYes];
                    [[theValue(wasFailBlockExecuted) should] beNo];
                });

                it(@"when geofences were never updated (and the geofence update fails)", ^{

                    [helper setupSuccessfulAsyncRequestWithBlock:^(NSURLRequest *request) {
                        registrationRequestCount += 1;
                    }];

                    [helper setupGeofencesForFailedUpdateWithBlock:^(NSArray *array) {
                        geofenceUpdateCount += 1;
                    }];

                    [PCFPush load];
                    [helper setupDefaultPLIST];

                    [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:helper.tags1 deviceAlias:TEST_DEVICE_ALIAS success:nil failure:failureBlock];
                    [[theValue(wasFailBlockExecuted) should] beYes];
                    [[theValue(registrationRequestCount) should] equal:theValue(1)];
                    [[theValue(geofenceUpdateCount) should] equal:theValue(1)];
                    wasFailBlockExecuted = NO;
                    [PCFPush load]; // Reset the state in the state engine

                    [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:helper.tags1 deviceAlias:TEST_DEVICE_ALIAS success:nil failure:failureBlock];
                    [[theValue(wasFailBlockExecuted) should] beYes];
                    [[theValue(registrationRequestCount) should] equal:theValue(1)]; // Shows that the second registration request was a no-op
                    [[theValue(geofenceUpdateCount) should] equal:theValue(2)];

                    [PCFPush load]; // Reset the state in the state engine
                    [helper setupGeofencesForSuccessfulUpdateWithLastModifiedTime:777L withBlock:^(NSArray *array) {
                        geofenceUpdateCount += 1;
                    }];
                    [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:helper.tags1 deviceAlias:TEST_DEVICE_ALIAS success:successBlock failure:nil];
                    [[theValue(wasSuccessBlockExecuted) should] beYes];
                    [[theValue(registrationRequestCount) should] equal:theValue(1)]; // Shows that the third registration request was a no-op
                    [[theValue(geofenceUpdateCount) should] equal:theValue(3)];
                });
            });
        });

        context(@"geofences disabled", ^{

            it(@"should make a POST request to the server", ^{

                __block BOOL wasSuccessBlockExecuted = NO;
                __block NSSet *expectedTags = helper.tags1;

                [helper setupGeofencesForSuccessfulUpdateWithLastModifiedTime:999L withBlock:^void(NSArray *params) {
                    int64_t timestamp = [params[2] longLongValue];
                    [[theValue(timestamp) should] beZero];
                }];

                [[PCFPushGeofenceUpdater shouldNot] receive:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:)];
                [[PCFPushGeofenceUpdater shouldNot] receive:@selector(clearAllGeofences:)];

                [[NSURLConnection shouldEventually] receive:@selector(pcfPushSendAsynchronousRequestWrapper:queue:completionHandler:) withCount:1];

                [helper setupSuccessfulAsyncRequestWithBlock:^(NSURLRequest *request) {

                    [[request.HTTPMethod should] equal:@"POST"];

                    NSError *error;
                    PCFPushRegistrationPostRequestData *requestBody = [PCFPushRegistrationPostRequestData pcfPushFromJSONData:request.HTTPBody error:&error];
                    [[error should] beNil];
                    [[requestBody shouldNot] beNil];
                    [[[NSSet setWithArray:requestBody.tags] should] equal:expectedTags];
                }];

                [helper setupDefaultPLISTWithFile:@"Pivotal-GeofencesDisabled"];

                void (^successBlock)() = ^{
                    wasSuccessBlockExecuted = YES;
                };

                void (^failureBlock)(NSError *) = ^(NSError *error) {
                    fail(@"registration failure block executed");
                };

                [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:helper.tags1 deviceAlias:TEST_DEVICE_ALIAS success:successBlock failure:failureBlock];

                [[theValue(wasSuccessBlockExecuted) shouldEventually] beTrue];
            });

            it(@"should bypass registering against Remote Push Server if Device Token matches the stored token.", ^{

                __block NSInteger registrationRequestCount = 0;
                __block BOOL wasSuccessBlockExecuted = NO;

                void (^successBlock)() = ^{
                    wasSuccessBlockExecuted = YES;
                };

                void (^failureBlock)(NSError *) = ^(NSError *error) {
                    fail(@"should not have failed");
                };

                [helper setupSuccessfulAsyncRequestWithBlock:^(NSURLRequest *request) {
                    registrationRequestCount += 1;
                }];

                [[PCFPushGeofenceUpdater shouldNot] receive:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:)];
                [[PCFPushGeofenceUpdater shouldNot] receive:@selector(clearAllGeofences:)];

                [PCFPush load];

                [helper setupDefaultPLISTWithFile:@"Pivotal-GeofencesDisabled"];

                [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:helper.tags1 deviceAlias:TEST_DEVICE_ALIAS success:nil failure:failureBlock];
                [[theValue(registrationRequestCount) should] equal:theValue(1)];
                [PCFPush load]; // Reset the state in the state engine

                [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:helper.tags1 deviceAlias:TEST_DEVICE_ALIAS success:successBlock failure:failureBlock];
                [[theValue(registrationRequestCount) should] equal:theValue(1)];
                [[theValue(wasSuccessBlockExecuted) should] beYes];
            });
        });
    });

    describe(@"handling various server responses", ^{
        __block BOOL wasExpectedResult = NO;

        beforeEach(^{
            wasExpectedResult = NO;
        });

        afterEach(^{
            [[theValue(wasExpectedResult) should] beTrue];
        });

        it(@"should handle an HTTP status error", ^{
            [NSURLConnection stub:@selector(pcfPushSendAsynchronousRequestWrapper:queue:completionHandler:) withBlock:^id(NSArray *params) {
                NSHTTPURLResponse *newResponse = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:400 HTTPVersion:nil headerFields:nil];
                CompletionHandler handler = params[2];
                handler(newResponse, nil, nil);
                return nil;
            }];

            [PCFPushClient sendRegisterRequestWithParameters:helper.params
                                                 deviceToken:helper.apnsDeviceToken
                                                     success:^{
                                                         wasExpectedResult = NO;
                                                     }
                                                     failure:^(NSError *error) {
                                                         [[error.domain should] equal:PCFPushErrorDomain];
                                                         [[theValue(error.code) should] equal:theValue(PCFPushBackEndRegistrationFailedHTTPStatusCode)];
                                                         wasExpectedResult = YES;
                                                     }];
        });

        it(@"should handle a successful response with empty data", ^{
            [NSURLConnection stub:@selector(pcfPushSendAsynchronousRequestWrapper:queue:completionHandler:) withBlock:^id(NSArray *params) {
                NSHTTPURLResponse *newResponse = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200 HTTPVersion:nil headerFields:nil];
                NSData *newData = [NSData data];
                CompletionHandler handler = params[2];
                handler(newResponse, newData, nil);
                return nil;
            }];

            [PCFPushClient sendRegisterRequestWithParameters:helper.params
                                                 deviceToken:helper.apnsDeviceToken
                                                     success:^{
                                                         wasExpectedResult = NO;
                                                     }
                                                     failure:^(NSError *error) {
                                                         [[error.domain should] equal:PCFPushErrorDomain];
                                                         [[theValue(error.code) should] equal:theValue(PCFPushBackEndRegistrationEmptyResponseData)];
                                                         wasExpectedResult = YES;
                                                     }];
        });

        it(@"should handle a successful response with nil data", ^{
            [NSURLConnection stub:@selector(pcfPushSendAsynchronousRequestWrapper:queue:completionHandler:) withBlock:^id(NSArray *params) {
                NSHTTPURLResponse *newResponse = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200 HTTPVersion:nil headerFields:nil];
                CompletionHandler handler = params[2];
                handler(newResponse, nil, nil);
                return nil;
            }];

            [PCFPushClient sendRegisterRequestWithParameters:helper.params
                                                 deviceToken:helper.apnsDeviceToken
                                                     success:^{
                                                         wasExpectedResult = NO;
                                                     }
                                                     failure:^(NSError *error) {
                                                         [[error.domain should] equal:PCFPushErrorDomain];
                                                         [[theValue(error.code) should] equal:theValue(PCFPushBackEndRegistrationEmptyResponseData)];
                                                         wasExpectedResult = YES;
                                                     }];
        });

        it(@"should handle a successful response with zero-length", ^{
            [NSURLConnection stub:@selector(pcfPushSendAsynchronousRequestWrapper:queue:completionHandler:) withBlock:^id(NSArray *params) {
                NSHTTPURLResponse *newResponse = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200 HTTPVersion:nil headerFields:nil];
                NSData *newData = [@"" dataUsingEncoding:NSUTF8StringEncoding];
                CompletionHandler handler = params[2];
                handler(newResponse, newData, nil);
                return nil;
            }];

            [PCFPushClient sendRegisterRequestWithParameters:helper.params
                                                 deviceToken:helper.apnsDeviceToken
                                                     success:^{
                                                         wasExpectedResult = NO;
                                                     }
                                                     failure:^(NSError *error) {
                                                         [[error.domain should] equal:PCFPushErrorDomain];
                                                         [[theValue(error.code) should] equal:theValue(PCFPushBackEndRegistrationEmptyResponseData)];
                                                         wasExpectedResult = YES;
                                                     }];
        });

        it(@"should handle a successful response that contains unparseable text", ^{
            [NSURLConnection stub:@selector(pcfPushSendAsynchronousRequestWrapper:queue:completionHandler:) withBlock:^id(NSArray *params) {
                NSHTTPURLResponse *newResponse = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200 HTTPVersion:nil headerFields:nil];
                NSData *newData = [@"This is not JSON" dataUsingEncoding:NSUTF8StringEncoding];
                CompletionHandler handler = params[2];
                handler(newResponse, newData, nil);
                return nil;
            }];

            [PCFPushClient sendRegisterRequestWithParameters:helper.params
                                                 deviceToken:helper.apnsDeviceToken
                                                     success:^{
                                                         wasExpectedResult = NO;
                                                     }
                                                     failure:^(NSError *error) {
                                                         [[error shouldNot] beNil];
                                                         wasExpectedResult = YES;
                                                     }];
        });

        it(@"should require a device_uuid in the server response", ^{
            [NSURLConnection stub:@selector(pcfPushSendAsynchronousRequestWrapper:queue:completionHandler:) withBlock:^id(NSArray *params) {
                NSHTTPURLResponse *newResponse = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200 HTTPVersion:nil headerFields:nil];
                NSDictionary *newJSON = @{@"os" : @"AmigaOS"};
                NSError *error;
                NSData *newData = [NSJSONSerialization dataWithJSONObject:newJSON options:NSJSONWritingPrettyPrinted error:&error];
                CompletionHandler handler = params[2];
                handler(newResponse, newData, nil);
                return nil;
            }];

            [PCFPushClient sendRegisterRequestWithParameters:helper.params
                                                 deviceToken:helper.apnsDeviceToken
                                                     success:^{
                                                         wasExpectedResult = NO;
                                                     }
                                                     failure:^(NSError *error) {
                                                         wasExpectedResult = YES;
                                                         [[error.domain should] equal:PCFPushErrorDomain];
                                                         [[theValue(error.code) should] equal:theValue(PCFPushBackEndRegistrationResponseDataNoDeviceUuid)];
                                                     }];
        });
    });

    describe(@"unregistration", ^{
        describe(@"successful unregistration from push server", ^{

            __block BOOL successBlockExecuted = NO;

            beforeEach(^{
                successBlockExecuted = NO;
                [helper setupDefaultPersistedParameters];
                [PCFPushPersistentStorage setGeofenceLastModifiedTime:1337L];
            });

            afterEach(^{
                [[[PCFPushPersistentStorage APNSDeviceToken] should] beNil];
                [[[PCFPushPersistentStorage serverDeviceID] should] beNil];
                [[[PCFPushPersistentStorage variantUUID] should] beNil];
                [[[PCFPushPersistentStorage deviceAlias] should] beNil];
            });

            context(@"when not already registered", ^{

                beforeEach(^{
                    [PCFPushPersistentStorage setServerDeviceID:nil];
                });

                // TODO - crashes here sometimes? race condition? watch this.
                it(@"should be considered a success if the device isn't currently registered", ^{
                    [[PCFPushGeofenceUpdater should] receive:@selector(clearAllGeofences:)];

                    [[[PCFPushPersistentStorage serverDeviceID] should] beNil];
                    [[NSURLConnection shouldNotEventually] receive:@selector(sendAsynchronousRequest:queue:completionHandler:)];

                    [PCFPush unregisterFromPCFPushNotificationsWithSuccess:^{
                        successBlockExecuted = YES;

                    }                                              failure:^(NSError *error) {
                        fail(@"unregistration failure block executed");
                    }];

                    [[theValue(successBlockExecuted) shouldEventually] beTrue];
                });
            });

            context(@"when already registered", ^{

                it(@"should succesfully unregister if the device has a persisted backEndDeviceUUID and should remove all persisted parameters when unregister is successful", ^{

                    [helper setupSuccessfulDeleteAsyncRequestAndReturnStatus:204];

                    [[PCFPushGeofenceUpdater should] receive:@selector(clearAllGeofences:)];
                    [[[PCFPushPersistentStorage serverDeviceID] shouldNot] beNil];
                    [[NSURLConnection shouldEventually] receive:@selector(pcfPushSendAsynchronousRequestWrapper:queue:completionHandler:)];

                    [PCFPush unregisterFromPCFPushNotificationsWithSuccess:^{
                        successBlockExecuted = YES;

                    }                                              failure:^(NSError *error) {
                        fail(@"unregistration failure block executed");
                    }];

                    [[theValue(successBlockExecuted) shouldEventually] beTrue];
                });
            });
        });

        describe(@"unsuccessful unregistration when device not registered on push server", ^{

            __block BOOL failureBlockExecuted = NO;

            beforeEach(^{
                [PCFPushPersistentStorage setGeofenceLastModifiedTime:1337L];
            });

            it(@"should perform failure block if server responds with a 404 (DeviceUUID not registered on server) ", ^{

                [helper setupDefaultPersistedParameters];
                [helper setupSuccessfulDeleteAsyncRequestAndReturnStatus:404];

                [[PCFPushGeofenceUpdater should] receive:@selector(clearAllGeofences:)];
                [[[PCFPushPersistentStorage serverDeviceID] shouldNot] beNil];
                [[NSURLConnection shouldEventually] receive:@selector(pcfPushSendAsynchronousRequestWrapper:queue:completionHandler:)];

                [PCFPush unregisterFromPCFPushNotificationsWithSuccess:^{
                    fail(@"unregistration success block executed");

                }                                              failure:^(NSError *error) {
                    failureBlockExecuted = YES;

                }];

                [[theValue(failureBlockExecuted) shouldEventually] beTrue];
            });
        });

        describe(@"unsuccessful unregistration", ^{

            __block BOOL failureBlockExecuted = NO;

            beforeEach(^{
                [PCFPushPersistentStorage setGeofenceLastModifiedTime:1337L];
            });

            it(@"should perform failure block if server request returns error", ^{
                [helper setupDefaultPersistedParameters];
                failureBlockExecuted = NO;

                [[PCFPushGeofenceUpdater should] receive:@selector(clearAllGeofences:)];
                [NSURLConnection stub:@selector(pcfPushSendAsynchronousRequestWrapper:queue:completionHandler:) withBlock:^id(NSArray *params) {
                    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:nil];
                    CompletionHandler handler = params[2];
                    handler(nil, nil, error);
                    return nil;
                }];

                [[NSURLConnection shouldEventually] receive:@selector(pcfPushSendAsynchronousRequestWrapper:queue:completionHandler:)];

                [PCFPush unregisterFromPCFPushNotificationsWithSuccess:^{
                    fail(@"unregistration success block executed incorrectly");

                }                                              failure:^(NSError *error) {
                    failureBlockExecuted = YES;

                }];

                [[theValue(failureBlockExecuted) shouldEventually] beTrue];
            });
        });

        describe(@"no geofences in the system during successful unregistration", ^{

            __block BOOL successBlockExecuted = NO;

            it(@"should not clear geofences during a unregistration", ^{
                [helper setupDefaultPersistedParameters];
                [helper setupSuccessfulDeleteAsyncRequestAndReturnStatus:204];

                [[NSURLConnection shouldEventually] receive:@selector(pcfPushSendAsynchronousRequestWrapper:queue:completionHandler:)];

                [[PCFPushGeofenceUpdater shouldNot] receive:@selector(clearAllGeofences:)];
                [[[PCFPushPersistentStorage serverDeviceID] shouldNot] beNil];

                [PCFPush unregisterFromPCFPushNotificationsWithSuccess:^{
                    successBlockExecuted = YES;

                }                                              failure:^(NSError *error) {
                    fail(@"unregistration failure block executed");
                }];

                [[theValue(successBlockExecuted) shouldEventually] beTrue];
            });
        });
    });

    describe(@"subscribing to tags", ^{

        describe(@"ensuring the device is registered", ^{

            beforeEach(^{
                [helper setupDefaultPersistedParameters];
            });

            it(@"should fail if not already registered at all", ^{
                [PCFPushPersistentStorage setAPNSDeviceToken:nil];
                [PCFPushPersistentStorage setServerDeviceID:nil];
            });

            it(@"should fail if not already registered with APNS", ^{
                [PCFPushPersistentStorage setAPNSDeviceToken:nil];
            });

            it(@"should fail if not already registered with CF", ^{
                [PCFPushPersistentStorage setServerDeviceID:nil];
            });

            afterEach(^{
                __block BOOL wasFailureBlockCalled = NO;
                [PCFPush subscribeToTags:helper.tags1 success:^{
                    fail(@"Should not have succeeded");
                }                failure:^(NSError *error) {
                    wasFailureBlockCalled = YES;
                }];

                [[theValue(wasFailureBlockCalled) shouldEventually] beTrue];
            });
        });

        describe(@"successful attempts", ^{

            __block NSInteger updateRegistrationCount;
            __block NSSet *expectedSubscribeTags;
            __block NSSet *expectedUnsubscribeTags;
            __block BOOL wasExpectedBlockCalled;

            beforeEach(^{
                updateRegistrationCount = 0;
                expectedSubscribeTags = nil;
                expectedUnsubscribeTags = nil;
                wasExpectedBlockCalled = NO;

                [helper setupDefaultPersistedParameters];

                [helper setupSuccessfulAsyncRequestWithBlock:^(NSURLRequest *request) {

                    [[request.HTTPMethod should] equal:@"PUT"];

                    updateRegistrationCount++;

                    NSError *error;
                    PCFPushRegistrationPutRequestData *requestBody = [PCFPushRegistrationPutRequestData pcfPushFromJSONData:request.HTTPBody error:&error];

                    [[error should] beNil];
                    [[requestBody shouldNot] beNil];

                    if (expectedSubscribeTags) {
                        [[[NSSet setWithArray:requestBody.subscribeTags] should] equal:expectedSubscribeTags];
                    } else {
                        [[requestBody.subscribeTags should] beNil];
                    }
                    if (expectedUnsubscribeTags) {
                        [[[NSSet setWithArray:requestBody.unsubscribeTags] should] equal:expectedUnsubscribeTags];
                    } else {
                        [[requestBody.unsubscribeTags should] beNil];
                    }
                }];
            });

            afterEach(^{
                [[theValue(wasExpectedBlockCalled) shouldEventually] beTrue];
            });

            // TODO - fix this test
//
//            it(@"should be able to register to some new tags and then fetch geofences if there have been no geofence updates (but fail to fetch geofences)", ^{
//                expectedSubscribeTags = helper.tags2;
//                expectedUnsubscribeTags = helper.tags1;
//
//                [helper setupGeofencesForFailedUpdate];
//                [[PCFPushGeofenceHandler shouldNot] receive:@selector(checkGeofencesForNewlySubscribedTagsWithStore:locationManager:)];
//                [[PCFPushGeofenceUpdater shouldEventually] receive:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:) withCount:1];
//
//                [PCFPush subscribeToTags:helper.tags2 success:^{
//                    fail(@"should not have succedeed");
//                }                failure:^(NSError *error) {
//                    wasExpectedBlockCalled = YES;
//                }];
//
//                [[[PCFPushPersistentStorage tags] should] equal:helper.tags2];
//                [[theValue(updateRegistrationCount) shouldEventually] equal:theValue(1)];
//            });
//
            context(@"geofences enabled", ^{

                beforeEach(^{
                    [helper setupDefaultPLIST];
                });

                it(@"should be able to register to some new tags and then fetch geofences if there have been no geofence updates", ^{
                    expectedSubscribeTags = helper.tags2;
                    expectedUnsubscribeTags = helper.tags1;

                    [helper setupGeofencesForSuccessfulUpdateWithLastModifiedTime:1337L];
                    [[PCFPushGeofenceHandler shouldNot] receive:@selector(reregisterGeofencesWithEngine:subscribedTags:)];
                    [[PCFPushGeofenceUpdater shouldEventually] receive:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:) withCount:1];

                    [PCFPush subscribeToTags:helper.tags2 success:^{
                        wasExpectedBlockCalled = YES;
                    }                failure:^(NSError *error) {
                        fail(@"Should not have failed");
                    }];

                    [[[PCFPushPersistentStorage tags] should] equal:helper.tags2];
                    [[theValue(updateRegistrationCount) shouldEventually] equal:theValue(1)];
                });

                it(@"should be able to register to some new tags and then stop if there have been some geofence updates in the past", ^{
                    expectedSubscribeTags = helper.tags2;
                    expectedUnsubscribeTags = helper.tags1;

                    [PCFPushPersistentStorage setGeofenceLastModifiedTime:8888L];
                    [[PCFPushGeofenceHandler should] receive:@selector(reregisterGeofencesWithEngine:subscribedTags:)];
                    [[PCFPushGeofenceUpdater shouldNot] receive:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:)];

                    [PCFPush subscribeToTags:helper.tags2 success:^{
                        wasExpectedBlockCalled = YES;
                    }                failure:^(NSError *error) {
                        fail(@"Should not have failed");
                    }];

                    [[[PCFPushPersistentStorage tags] should] equal:helper.tags2];
                    [[theValue(updateRegistrationCount) shouldEventually] equal:theValue(1)];
                });

                it(@"should not call the update API if provided the same tags (but then do a geofence update if required - but the geofence update fails)", ^{
                    [helper setupGeofencesForFailedUpdate];

                    [[PCFPushGeofenceHandler shouldNot] receive:@selector(reregisterGeofencesWithEngine:subscribedTags:)];
                    [[PCFPushGeofenceUpdater should] receive:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:) withCount:1];

                    [PCFPush subscribeToTags:helper.tags1 success:^{
                        fail(@"Should not have failed");
                    }                failure:^(NSError *error) {
                        wasExpectedBlockCalled = YES;
                    }];

                    [[[PCFPushPersistentStorage tags] should] equal:helper.tags1];
                    [[theValue(updateRegistrationCount) shouldEventually] equal:theValue(0)];
                });

                it(@"should not call the update API if provided the same tags (but then do a geofence update if required)", ^{
                    [helper setupGeofencesForSuccessfulUpdateWithLastModifiedTime:1337L];

                    [[PCFPushGeofenceHandler shouldNot] receive:@selector(reregisterGeofencesWithEngine:subscribedTags:)];
                    [[PCFPushGeofenceUpdater should] receive:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:) withCount:1];

                    [PCFPush subscribeToTags:helper.tags1 success:^{
                        wasExpectedBlockCalled = YES;
                    }                failure:^(NSError *error) {
                        fail(@"Should not have failed");
                    }];

                    [[[PCFPushPersistentStorage tags] should] equal:helper.tags1];
                    [[theValue(updateRegistrationCount) shouldEventually] equal:theValue(0)];
                });

                it(@"should not call the update API if provided the same tags (and then skip the geofence update if not required)", ^{
                    [PCFPushPersistentStorage setGeofenceLastModifiedTime:999L];

                    [[PCFPushGeofenceHandler shouldNot] receive:@selector(reregisterGeofencesWithEngine:subscribedTags:)];
                    [[PCFPushGeofenceUpdater shouldNot] receive:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:)];

                    [PCFPush subscribeToTags:helper.tags1 success:^{
                        wasExpectedBlockCalled = YES;
                    }                failure:^(NSError *error) {
                        fail(@"Should not have failed");
                    }];

                    [[[PCFPushPersistentStorage tags] should] equal:helper.tags1];
                    [[theValue(updateRegistrationCount) shouldEventually] equal:theValue(0)];
                });
            });

            context(@"geofences disabled", ^{

                beforeEach(^{
                    [helper setupDefaultPLISTWithFile:@"Pivotal-GeofencesDisabled"];
                });

                afterEach(^{
                    [[theValue([PCFPushPersistentStorage lastGeofencesModifiedTime]) should] equal:theValue(PCF_NEVER_UPDATED_GEOFENCES)];
                });

                it(@"should be able to register to some new tags", ^{
                    expectedSubscribeTags = helper.tags2;
                    expectedUnsubscribeTags = helper.tags1;

                    [[PCFPushGeofenceHandler shouldNot] receive:@selector(reregisterGeofencesWithEngine:subscribedTags:)];
                    [[PCFPushGeofenceUpdater shouldNot] receive:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:)];
                    [[PCFPushGeofenceUpdater shouldNot] receive:@selector(clearAllGeofences:)];

                    [PCFPush subscribeToTags:helper.tags2 success:^{
                        wasExpectedBlockCalled = YES;
                    }                failure:^(NSError *error) {
                        fail(@"Should not have failed");
                    }];

                    [[[PCFPushPersistentStorage tags] should] equal:helper.tags2];
                    [[theValue(updateRegistrationCount) shouldEventually] equal:theValue(1)];
                });

                it(@"should be able to register to some new tags and then clear the currently monitored geofences", ^{
                    expectedSubscribeTags = helper.tags2;
                    expectedUnsubscribeTags = helper.tags1;

                    [PCFPushPersistentStorage setGeofenceLastModifiedTime:8888L];
                    [[PCFPushGeofenceHandler shouldNot] receive:@selector(reregisterGeofencesWithEngine:subscribedTags:)];
                    [[PCFPushGeofenceUpdater shouldNot] receive:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:)];
                    [[PCFPushGeofenceUpdater should] receive:@selector(clearAllGeofences:)];
                    [PCFPushGeofenceUpdater stub:@selector(clearAllGeofences:) withBlock:^id(NSArray *params) {
                        [PCFPushPersistentStorage setGeofenceLastModifiedTime:PCF_NEVER_UPDATED_GEOFENCES];
                        return nil;
                    }];

                    [PCFPush subscribeToTags:helper.tags2 success:^{
                        wasExpectedBlockCalled = YES;
                    }                failure:^(NSError *error) {
                        fail(@"Should not have failed");
                    }];

                    [[[PCFPushPersistentStorage tags] should] equal:helper.tags2];
                    [[theValue(updateRegistrationCount) shouldEventually] equal:theValue(1)];
                });

                it(@"should not call the update API if provided the same tags (i.e.: no-op)", ^{
                    [[PCFPushGeofenceHandler shouldNot] receive:@selector(reregisterGeofencesWithEngine:subscribedTags:)];
                    [[PCFPushGeofenceUpdater shouldNot] receive:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:) withCount:1];
                    [[PCFPushGeofenceUpdater shouldNot] receive:@selector(clearAllGeofences:)];

                    [PCFPush subscribeToTags:helper.tags1 success:^{
                        wasExpectedBlockCalled = YES;
                    }                failure:^(NSError *error) {
                        fail(@"Should not have failed");
                    }];

                    [[[PCFPushPersistentStorage tags] should] equal:helper.tags1];
                    [[theValue(updateRegistrationCount) shouldEventually] equal:theValue(0)];
                });

                it(@"should not call the update API if provided the same tags (and then clear the geofences)", ^{
                    [PCFPushPersistentStorage setGeofenceLastModifiedTime:999L];

                    [[PCFPushGeofenceHandler shouldNot] receive:@selector(reregisterGeofencesWithEngine:subscribedTags:)];
                    [[PCFPushGeofenceUpdater shouldNot] receive:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:)];
                    [[PCFPushGeofenceUpdater should] receive:@selector(clearAllGeofences:)];
                    [PCFPushGeofenceUpdater stub:@selector(clearAllGeofences:) withBlock:^id(NSArray *params) {
                        [PCFPushPersistentStorage setGeofenceLastModifiedTime:PCF_NEVER_UPDATED_GEOFENCES];
                        return nil;
                    }];

                    [PCFPush subscribeToTags:helper.tags1 success:^{
                        wasExpectedBlockCalled = YES;
                    }                failure:^(NSError *error) {
                        fail(@"Should not have failed");
                    }];

                    [[[PCFPushPersistentStorage tags] should] equal:helper.tags1];
                    [[theValue(updateRegistrationCount) shouldEventually] equal:theValue(0)];
                });
            });
        });

        describe(@"unsuccessful attempts", ^{

            __block BOOL wasFailBlockCalled;
            __block BOOL wasRequestCalled;

            beforeEach(^{
                [helper setupDefaultPersistedParameters];
                [helper setupDefaultPLIST];
                wasFailBlockCalled = NO;
                wasRequestCalled = NO;
            });

            afterEach(^{
                [[theValue(wasFailBlockCalled) shouldEventually] beTrue];
                [[theValue(wasRequestCalled) shouldEventually] beTrue];
            });

            it(@"Should fail correctly if there is a network error", ^{
                [helper setupAsyncRequestWithBlock:^(NSURLRequest *request, NSURLResponse **resultResponse, NSData **resultData, NSError **resultError) {

                    *resultResponse = nil;
                    *resultError = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorSecureConnectionFailed userInfo:nil];
                    *resultData = nil;
                    wasRequestCalled = YES;
                }];

                [[PCFPushGeofenceHandler shouldNot] receive:@selector(reregisterGeofencesWithEngine:subscribedTags:)];
                [[PCFPushGeofenceUpdater shouldNot] receive:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:)];

                [PCFPush subscribeToTags:helper.tags2 success:^{
                    fail(@"should not have succeeded");
                }                failure:^(NSError *error) {
                    [[error.domain should] equal:NSURLErrorDomain];
                    wasFailBlockCalled = YES;
                }];
            });

            it(@"Should fail correctly if the response data is bad", ^{
                [helper setupAsyncRequestWithBlock:^(NSURLRequest *request, NSURLResponse **resultResponse, NSData **resultData, NSError **resultError) {

                    *resultResponse = [[NSHTTPURLResponse alloc] initWithURL:request.URL statusCode:200 HTTPVersion:@"1.1" headerFields:nil];
                    *resultError = nil;
                    *resultData = [NSData data];
                    wasRequestCalled = YES;
                }];

                [[PCFPushGeofenceHandler shouldNot] receive:@selector(reregisterGeofencesWithEngine:subscribedTags:)];
                [[PCFPushGeofenceUpdater shouldNot] receive:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:)];

                [PCFPush subscribeToTags:helper.tags2 success:^{
                    fail(@"should not have succeeded");
                }                failure:^(NSError *error) {
                    [[error.domain should] equal:PCFPushErrorDomain];
                    wasFailBlockCalled = YES;
                }];
            });
        });
    });

    describe(@"handling remote notifications", ^{

        __block BOOL wasCompletionHandlerCalled;

        NSDictionary *const userInfo = @{ @"aps" : @{ @"content-available" : @1 }, @"pivotal.push.geofence_update_available" : @"true" };

        beforeEach(^{
            wasCompletionHandlerCalled = NO;
        });

        context(@"processing geofence updates", ^{

            beforeEach(^{
                [helper setupDefaultPLIST];
            });

            afterEach(^{
                [[theValue(wasCompletionHandlerCalled) shouldEventually] beYes];
            });

            it(@"should process geofence updates with some data available on server", ^{

                [PCFPushGeofenceUpdater stub:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:) withBlock:^id(NSArray *params) {
                    NSDictionary *actualUserInfo = params[1];
                    [[actualUserInfo should] equal:userInfo];
                    void (^successBlock)(void) = params[4];
                    if (successBlock) {
                        successBlock();
                    }
                    return nil;
                }];

                [PCFPush didReceiveRemoteNotification:userInfo completionHandler:^(BOOL wasIgnored, UIBackgroundFetchResult fetchResult, NSError *error) {
                    [[theValue(wasIgnored) should] beNo];
                    [[theValue(fetchResult) should] equal:theValue(UIBackgroundFetchResultNewData)];
                    [[error should] beNil];
                    wasCompletionHandlerCalled = YES;
                }];
            });

            it(@"should handle server errors in geofence updates", ^{

                [PCFPushGeofenceUpdater stub:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:) withBlock:^id(NSArray *params) {
                    NSDictionary *actualUserInfo = params[1];
                    [[actualUserInfo should] equal:userInfo];
                    void (^failureBlock)(NSError *) = params[5];
                    if (failureBlock) {
                        failureBlock([NSError errorWithDomain:@"FAKE ERROR" code:0 userInfo:nil]);
                    }
                    return nil;
                }];

                [PCFPush didReceiveRemoteNotification:userInfo completionHandler:^(BOOL wasIgnored, UIBackgroundFetchResult fetchResult, NSError *error) {
                    [[theValue(wasIgnored) should] beNo];
                    [[theValue(fetchResult) should] equal:theValue(UIBackgroundFetchResultFailed)];
                    [[error shouldNot] beNil];
                    wasCompletionHandlerCalled = YES;
                }];
            });
        });

        context(@"geofences are disabled", ^{

            afterEach(^{
                [[theValue(wasCompletionHandlerCalled) shouldEventually] beYes];
            });

            it(@"should process geofence updates with some data available on server", ^{

                [helper setupDefaultPLISTWithFile:@"Pivotal-GeofencesDisabled"];

                [[PCFPushGeofenceUpdater shouldNot] receive:@selector(startGeofenceUpdate:userInfo:timestamp:tags:success:failure:)];

                [PCFPush didReceiveRemoteNotification:userInfo completionHandler:^(BOOL wasIgnored, UIBackgroundFetchResult fetchResult, NSError *error) {
                    [[theValue(wasIgnored) should] beYes];
                    [[theValue(fetchResult) should] equal:theValue(UIBackgroundFetchResultNoData)];
                    [[error should] beNil];
                    wasCompletionHandlerCalled = YES;
                }];
            });
        });

        context(@"other kinds of messages", ^{

            beforeEach(^{
                [helper setupDefaultPLIST];
            });

            afterEach(^{
                [[theValue(wasCompletionHandlerCalled) shouldEventually] beYes];
            });

            it(@"should ignore notifications with nil data", ^{
                [PCFPush didReceiveRemoteNotification:nil completionHandler:^(BOOL wasIgnored, UIBackgroundFetchResult fetchResult, NSError *error) {
                    [[theValue(wasIgnored) should] beYes];
                    [[theValue(fetchResult) should] equal:theValue(UIBackgroundFetchResultNoData)];
                    [[error should] beNil];
                    wasCompletionHandlerCalled = YES;
                }];
            });

            it(@"should ignore notification when the user data is empty", ^{
                [PCFPush didReceiveRemoteNotification:@{} completionHandler:^(BOOL wasIgnored, UIBackgroundFetchResult fetchResult, NSError *error) {
                    [[theValue(wasIgnored) should] beYes];
                    [[theValue(fetchResult) should] equal:theValue(UIBackgroundFetchResultNoData)];
                    [[error should] beNil];
                    wasCompletionHandlerCalled = YES;
                }];
            });

            it(@"should ignore notification when it's some regular push message (not a background fetch)", ^{
                [PCFPush didReceiveRemoteNotification:@{ @"aps" : @{ @"alert" : @"some message" } }  completionHandler:^(BOOL wasIgnored, UIBackgroundFetchResult fetchResult, NSError *error) {
                    [[theValue(wasIgnored) should] beYes];
                    [[theValue(fetchResult) should] equal:theValue(UIBackgroundFetchResultNoData)];
                    [[error should] beNil];
                    wasCompletionHandlerCalled = YES;
                }];
            });

            it(@"should ignore background notifications that are not for us", ^{
                [PCFPush didReceiveRemoteNotification:@{ @"aps" : @{ @"content-available" : @1 } }  completionHandler:^(BOOL wasIgnored, UIBackgroundFetchResult fetchResult, NSError *error) {
                    [[theValue(wasIgnored) should] beYes];
                    [[theValue(fetchResult) should] equal:theValue(UIBackgroundFetchResultNoData)];
                    [[error should] beNil];
                    wasCompletionHandlerCalled = YES;
                }];
            });
        });

        context(@"failed completion handler", ^{
            it(@"should throw an exception if a handler is not provided", ^{
                [[theBlock(^{
                    [PCFPush didReceiveRemoteNotification:@{} completionHandler:nil];
                }) should] raiseWithName:NSInvalidArgumentException];
            });
        });
    });

    describe(@"geofence events", ^{

        __block CLRegion *region;
        __block CLLocationManager *locationManager;

        beforeEach(^{
            region = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(33.0, 44.0) radius:100.0 identifier:@"PCF_3_66"];
            locationManager = [CLLocationManager mock];
            NSSet *monitoredRegions = [NSSet setWithObject:region];
            [locationManager stub:@selector(monitoredRegions) andReturn:monitoredRegions];
        });

        context(@"geofences enabled", ^{

            beforeEach(^{
                [helper setupDefaultPLIST];
            });

            it(@"should process geofence on exiting region", ^{
                [[PCFPushGeofenceHandler should] receive:@selector(processRegion:store:engine:state:tags:)];
                [[PCFPushClient shared] locationManager:locationManager didExitRegion:region];
            });

            it(@"should process geofence inside region", ^{
                [[PCFPushGeofenceHandler should] receive:@selector(processRegion:store:engine:state:tags:)];
                [[PCFPushClient shared] locationManager:locationManager didDetermineState:CLRegionStateInside forRegion:region];
            });

            it(@"should not process geofence", ^{
                [[PCFPushGeofenceHandler shouldNot] receive:@selector(processRegion:store:engine:state:tags:)];
                [[PCFPushClient shared] locationManager:locationManager didDetermineState:CLRegionStateOutside forRegion:region];
                [[PCFPushClient shared] locationManager:locationManager didDetermineState:CLRegionStateUnknown forRegion:region];
            });
        });

        context(@"geofences disabled", ^{

            beforeEach(^{
                [helper setupDefaultPLISTWithFile:@"Pivotal-GeofencesDisabled"];
            });

            it(@"should process geofence on exiting region", ^{
                [[PCFPushGeofenceHandler shouldNot] receive:@selector(processRegion:store:engine:state:tags:)];
                [[PCFPushClient shared] locationManager:locationManager didExitRegion:region];
            });

            it(@"should process geofence inside region", ^{
                [[PCFPushGeofenceHandler shouldNot] receive:@selector(processRegion:store:engine:state:tags:)];
                [[PCFPushClient shared] locationManager:locationManager didDetermineState:CLRegionStateInside forRegion:region];
            });

            it(@"should not process geofence", ^{
                [[PCFPushGeofenceHandler shouldNot] receive:@selector(processRegion:store:engine:state:tags:)];
                [[PCFPushClient shared] locationManager:locationManager didDetermineState:CLRegionStateOutside forRegion:region];
                [[PCFPushClient shared] locationManager:locationManager didDetermineState:CLRegionStateUnknown forRegion:region];
            });
        });
    });
});

SPEC_END
