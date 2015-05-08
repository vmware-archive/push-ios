//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "Kiwi.h"
#import "PCFPush.h"
#import "PCFPushErrors.h"
#import "PCFPushParameters.h"
#import "PCFPushClientTest.h"
#import "PCFPushSpecsHelper.h"
#import "PCFPushURLConnection.h"
#import "NSObject+PCFJSONizable.h"
#import "PCFPushGeofenceUpdater.h"
#import "PCFPushGeofenceHandler.h"
#import "PCFPushPersistentStorage.h"
#import "PCFPushRegistrationPutRequestData.h"
#import "NSURLConnection+PCFPushAsync2Sync.h"
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

            __block void (^successBlock)() = ^{
            };
            __block void (^failureBlock)(NSError *) = ^(NSError *error) {
            };

            beforeEach(^{
                [helper setupDefaultPLIST];
                [helper setupSuccessfulAsyncRequest];
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

    describe(@"updating registration", ^{

        __block NSInteger successCount;
        __block NSInteger updateRegistrationCount;
        __block void (^testBlock)(SEL, id);
        __block NSSet *expectedSubscribeTags;
        __block NSSet *expectedUnsubscribeTags;

        beforeEach(^{
            successCount = 0;
            updateRegistrationCount = 0;
            expectedSubscribeTags = nil;
            expectedUnsubscribeTags = nil;


            [helper setupSuccessfulAsyncRequestWithBlock:^(NSURLRequest *request) {

                [[request.HTTPMethod should] equal:@"PUT"];

                updateRegistrationCount++;

                NSError *error;
                PCFPushRegistrationPutRequestData *requestBody = [PCFPushRegistrationPutRequestData pcf_fromJSONData:request.HTTPBody error:&error];

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
                [[requestBody.variantUUID should] beNil];
                [[requestBody.deviceAlias should] equal:TEST_DEVICE_ALIAS_1];
            }];

            [[NSURLConnection shouldEventually] receive:@selector(sendAsynchronousRequest:queue:completionHandler:)];

            testBlock = ^(SEL sel, id newPersistedValue) {

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

        context(@"with no geofence update in the past (and so will update geofences this time)", ^{

            beforeEach(^{
                [helper setupGeofencesForSuccessfulUpdateWithLastModifiedTime:1337L];
                [[PCFPushGeofenceUpdater should] receive:@selector(startGeofenceUpdate:userInfo:timestamp:success:failure:) withCount:1];
                [[PCFPushGeofenceUpdater shouldNot] receive:@selector(clearGeofences:error:)];
            });

            afterEach(^{
                [[theValue([PCFPushPersistentStorage lastGeofencesModifiedTime]) should] equal:theValue(1337L)];
            });

            it(@"should update the push registration and geofences after the variantUuid changes", ^{
                testBlock(@selector(setVariantUUID:), @"DIFFERENT STRING");
            });

            it(@"should update the push registration and geofences after the variantUuid is initially set", ^{
                testBlock(@selector(setVariantUUID:), nil);
            });

            it(@"should update the push registration and geofences after the variantSecret changes", ^{
                testBlock(@selector(setVariantSecret:), @"DIFFERENT STRING");
            });

            it(@"should update the push registration and geofences after the variantSecret is initially set", ^{
                testBlock(@selector(setVariantSecret:), nil);
            });

            it(@"should update the push registration and geofences after the deviceAlias changes (with geofence update)", ^{
                testBlock(@selector(setDeviceAlias:), @"DIFFERENT STRING");
            });

            it(@"should update the push registration and geofences after the deviceAlias is initially set (with geofence update)", ^{
                testBlock(@selector(setDeviceAlias:), nil);
            });

            it(@"should update the push registration and geofences after the APNSDeviceToken changes", ^{
                testBlock(@selector(setAPNSDeviceToken:), [@"DIFFERENT TOKEN" dataUsingEncoding:NSUTF8StringEncoding]);
            });

            it(@"should update the push registration and geofences after the tags change to a different value", ^{
                expectedSubscribeTags = helper.tags1;
                expectedUnsubscribeTags = [NSSet setWithArray:@[@"DIFFERENT TAG"]];
                testBlock(@selector(setTags:), expectedUnsubscribeTags);
            });

            it(@"should update the push registration and geofences after tags initially set from nil", ^{
                expectedSubscribeTags = helper.tags1;
                testBlock(@selector(setTags:), nil);
            });

            it(@"should update the push registration and geofences after tags initially set from empty", ^{
                expectedSubscribeTags = helper.tags1;
                testBlock(@selector(setTags:), [NSSet set]);
            });

            it(@"should update the push registration and geofences after tags change to nil", ^{
                helper.params.pushTags = nil;
                expectedUnsubscribeTags = helper.tags1;
                testBlock(@selector(setTags:), helper.tags1);
            });

            it(@"should update the push registration and geofences after tags change to empty", ^{
                helper.params.pushTags = [NSSet set];
                expectedUnsubscribeTags = helper.tags1;
                testBlock(@selector(setTags:), helper.tags1);
            });
        });

        context(@"with geofences updated in the past (and so will skip a geofence update this time)", ^{

            beforeEach(^{
                [PCFPushPersistentStorage setGeofenceLastModifiedTime:1337L];
                [[PCFPushGeofenceUpdater shouldNot] receive:@selector(startGeofenceUpdate:userInfo:timestamp:success:failure:)];
                [[PCFPushGeofenceUpdater shouldNot] receive:@selector(clearGeofences:error:)];
            });

            afterEach(^{
                [[theValue([PCFPushPersistentStorage lastGeofencesModifiedTime]) should] equal:theValue(1337L)];
            });

            it(@"should update the push registration after the deviceAlias changes (without geofence update)", ^{
                testBlock(@selector(setDeviceAlias:), @"DIFFERENT STRING");
            });

            it(@"should update the push registration after the deviceAlias is initially set (without geofence update)", ^{
                testBlock(@selector(setDeviceAlias:), nil);
            });

            it(@"should update the push registration after the APNSDeviceToken changes", ^{
                testBlock(@selector(setAPNSDeviceToken:), [@"DIFFERENT TOKEN" dataUsingEncoding:NSUTF8StringEncoding]);
            });

            it(@"should update the push registration after the tags change to a different value", ^{
                expectedSubscribeTags = helper.tags1;
                expectedUnsubscribeTags = [NSSet setWithArray:@[@"DIFFERENT TAG"]];
                testBlock(@selector(setTags:), expectedUnsubscribeTags);
            });

            it(@"should update the push registration after tags initially set from nil", ^{
                expectedSubscribeTags = helper.tags1;
                testBlock(@selector(setTags:), nil);
            });

            it(@"should update the push registration after tags initially set from empty", ^{
                expectedSubscribeTags = helper.tags1;
                testBlock(@selector(setTags:), [NSSet set]);
            });

            it(@"should update the push registration after tags change to nil", ^{
                helper.params.pushTags = nil;
                expectedUnsubscribeTags = helper.tags1;
                testBlock(@selector(setTags:), helper.tags1);
            });

            it(@"should update the push registration after tags change to empty", ^{
                helper.params.pushTags = [NSSet set];
                expectedUnsubscribeTags = helper.tags1;
                testBlock(@selector(setTags:), helper.tags1);
            });
        });

        context(@"with geofences updated in the past (and will still do a geofence reset and update this time)", ^{

            beforeEach(^{
                [PCFPushPersistentStorage setGeofenceLastModifiedTime:1337L];
                [helper setupClearGeofencesForSuccess];
                [helper setupGeofencesForSuccessfulUpdateWithLastModifiedTime:2784L];
                [[PCFPushGeofenceUpdater should] receive:@selector(clearGeofences:error:) withCount:1];
                [[PCFPushGeofenceUpdater should] receive:@selector(startGeofenceUpdate:userInfo:timestamp:success:failure:) withCount:1];
            });

            afterEach(^{
                [[theValue([PCFPushPersistentStorage lastGeofencesModifiedTime]) should] equal:theValue(2784L)];
            });

            it(@"should update the push registration and geofences after the variantUuid changes", ^{
                testBlock(@selector(setVariantUUID:), @"DIFFERENT STRING");
            });

            it(@"should update the push registration and geofences after the variantUuid is initially set", ^{
                testBlock(@selector(setVariantUUID:), nil);
            });

            it(@"should update the push registration and geofences after the variantSecret changes", ^{
                testBlock(@selector(setVariantSecret:), @"DIFFERENT STRING");
            });

            it(@"should update the push registration and geofences after the variantSecret is initially set", ^{
                testBlock(@selector(setVariantSecret:), nil);
            });
        });
    });

    describe(@"successful registration", ^{

        it(@"should make a POST request to the server and update geofences on a new registration", ^{

            __block BOOL wasSuccessBlockExecuted = NO;
            __block NSSet *expectedTags = helper.tags1;

            [helper setupGeofencesForSuccessfulUpdateWithLastModifiedTime:999L withBlock:^void(NSArray *params) {
                int64_t timestamp = [params[2] longLongValue];
                [[theValue(timestamp) should] beZero];
            }];
            [[PCFPushGeofenceUpdater should] receive:@selector(startGeofenceUpdate:userInfo:timestamp:success:failure:) withCount:1];

            [[NSURLConnection should] receive:@selector(sendAsynchronousRequest:queue:completionHandler:) withCount:1];

            [helper setupSuccessfulAsyncRequestWithBlock:^(NSURLRequest *request) {

                [[request.HTTPMethod should] equal:@"POST"];

                NSError *error;
                PCFPushRegistrationPostRequestData *requestBody = [PCFPushRegistrationPostRequestData pcf_fromJSONData:request.HTTPBody error:&error];
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

    describe(@"handling various server responses", ^{
        __block BOOL wasExpectedResult = NO;

        beforeEach(^{
            wasExpectedResult = NO;
        });

        afterEach(^{
            [[theValue(wasExpectedResult) should] beTrue];
        });

        it(@"should handle an HTTP status error", ^{
            NSError *err;
            [helper swizzleAsyncRequestWithSelector:@selector(HTTPErrorResponseRequest:queue:completionHandler:) error:&err];

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
            NSError *err;
            [helper swizzleAsyncRequestWithSelector:@selector(emptyDataResponseRequest:queue:completionHandler:) error:&err];

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
            NSError *err;
            [helper swizzleAsyncRequestWithSelector:@selector(nilDataResponseRequest:queue:completionHandler:) error:&err];

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
            NSError *err;
            [helper swizzleAsyncRequestWithSelector:@selector(zeroLengthDataResponseRequest:queue:completionHandler:) error:&err];

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
            NSError *err;
            [helper swizzleAsyncRequestWithSelector:@selector(unparseableDataResponseRequest:queue:completionHandler:) error:&err];

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
            NSError *err;
            [helper swizzleAsyncRequestWithSelector:@selector(missingUUIDResponseRequest:queue:completionHandler:) error:&err];

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

                    [[[PCFPushPersistentStorage serverDeviceID] shouldNot] beNil];
                    [[NSURLConnection shouldEventually] receive:@selector(sendAsynchronousRequest:queue:completionHandler:)];

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

            it(@"should perform failure block if server responds with a 404 (DeviceUUID not registered on server) ", ^{

                [helper setupDefaultPersistedParameters];
                [helper setupSuccessfulDeleteAsyncRequestAndReturnStatus:404];

                [[NSURLConnection shouldEventually] receive:@selector(sendAsynchronousRequest:queue:completionHandler:)];

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

            it(@"should perform failure block if server request returns error", ^{
                [helper setupDefaultPersistedParameters];
                failureBlockExecuted = NO;

                [NSURLConnection stub:@selector(sendAsynchronousRequest:queue:completionHandler:) withBlock:^id(NSArray *params) {
                    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:nil];
                    CompletionHandler handler = params[2];
                    handler(nil, nil, error);
                    return nil;
                }];

                [[NSURLConnection shouldEventually] receive:@selector(sendAsynchronousRequest:queue:completionHandler:)];

                [PCFPush unregisterFromPCFPushNotificationsWithSuccess:^{
                    fail(@"unregistration success block executed incorrectly");

                }                                              failure:^(NSError *error) {
                    failureBlockExecuted = YES;

                }];

                [[theValue(failureBlockExecuted) shouldEventually] beTrue];
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
                [helper setupDefaultPLIST];

                [helper setupSuccessfulAsyncRequestWithBlock:^(NSURLRequest *request) {

                    [[request.HTTPMethod should] equal:@"PUT"];

                    updateRegistrationCount++;

                    NSError *error;
                    PCFPushRegistrationPutRequestData *requestBody = [PCFPushRegistrationPutRequestData pcf_fromJSONData:request.HTTPBody error:&error];

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

            it(@"should be able to register to some new tags and then fetch geofences if there have been no geofence updates (but fail to fetch geofences)", ^{
                expectedSubscribeTags = helper.tags2;
                expectedUnsubscribeTags = helper.tags1;

                [helper setupGeofencesForFailedUpdate];
                [[PCFPushGeofenceUpdater shouldEventually] receive:@selector(startGeofenceUpdate:userInfo:timestamp:success:failure:) withCount:1];

                [PCFPush subscribeToTags:helper.tags2 success:^{
                    fail(@"should not have succedeed");
                }                failure:^(NSError *error) {
                    wasExpectedBlockCalled = YES;
                }];

                [[[PCFPushPersistentStorage tags] should] equal:helper.tags2];
                [[theValue(updateRegistrationCount) shouldEventually] equal:theValue(1)];
            });

            it(@"should be able to register to some new tags and then fetch geofences if there have been no geofence updates", ^{
                expectedSubscribeTags = helper.tags2;
                expectedUnsubscribeTags = helper.tags1;

                [helper setupGeofencesForSuccessfulUpdateWithLastModifiedTime:1337L];
                [[PCFPushGeofenceUpdater shouldEventually] receive:@selector(startGeofenceUpdate:userInfo:timestamp:success:failure:) withCount:1];

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
                [[PCFPushGeofenceUpdater shouldNot] receive:@selector(startGeofenceUpdate:userInfo:timestamp:success:failure:)];

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
                [[PCFPushGeofenceUpdater should] receive:@selector(startGeofenceUpdate:userInfo:timestamp:success:failure:) withCount:1];

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
                [[PCFPushGeofenceUpdater should] receive:@selector(startGeofenceUpdate:userInfo:timestamp:success:failure:) withCount:1];

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
                [[PCFPushGeofenceUpdater shouldNot] receive:@selector(startGeofenceUpdate:userInfo:timestamp:success:failure:)];

                [PCFPush subscribeToTags:helper.tags1 success:^{
                    wasExpectedBlockCalled = YES;
                }                failure:^(NSError *error) {
                    fail(@"Should not have failed");
                }];

                [[[PCFPushPersistentStorage tags] should] equal:helper.tags1];
                [[theValue(updateRegistrationCount) shouldEventually] equal:theValue(0)];
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

                [[PCFPushGeofenceUpdater shouldNot] receive:@selector(startGeofenceUpdate:userInfo:timestamp:success:failure:)];

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

                [[PCFPushGeofenceUpdater shouldNot] receive:@selector(startGeofenceUpdate:userInfo:timestamp:success:failure:)];

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

        beforeEach(^{
            wasCompletionHandlerCalled = NO;
        });

        context(@"processing geofence updates", ^{
            afterEach(^{
                [[theValue(wasCompletionHandlerCalled) shouldEventually] beYes];
            });

            NSDictionary *const userInfo = @{ @"aps" : @{ @"content-available" : @1 }, @"pivotal.push.geofence_update_available" : @"true" };

            it(@"should process geofence updates with some data available on server", ^{

                [PCFPushGeofenceUpdater stub:@selector(startGeofenceUpdate:userInfo:timestamp:success:failure:) withBlock:^id(NSArray *params) {
                    NSDictionary *actualUserInfo = params[1];
                    [[actualUserInfo should] equal:userInfo];
                    void (^successBlock)(void) = params[3];
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

                [PCFPushGeofenceUpdater stub:@selector(startGeofenceUpdate:userInfo:timestamp:success:failure:) withBlock:^id(NSArray *params) {
                    NSDictionary *actualUserInfo = params[1];
                    [[actualUserInfo should] equal:userInfo];
                    void (^failureBlock)(NSError *) = params[4];
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

        context(@"other kinds of messages", ^{
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

        beforeEach(^{
           region = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(33.0, 44.0) radius:100.0 identifier:@"PCF_3_66"];
        });

        it(@"should process geofence on exiting region", ^{
            [[PCFPushGeofenceHandler should] receive:@selector(processRegion:store:engine:state:)];
            [[PCFPushClient shared] locationManager:nil didExitRegion:region];
        });

        it(@"should process geofence inside region", ^{
            [[PCFPushGeofenceHandler should] receive:@selector(processRegion:store:engine:state:)];
            [[PCFPushClient shared] locationManager:nil didDetermineState:CLRegionStateInside forRegion:region];
        });

        it(@"should not process geofence", ^{
            [[PCFPushGeofenceHandler shouldNot] receive:@selector(processRegion:store:engine:state:)];
            [[PCFPushClient shared] locationManager:nil didDetermineState:CLRegionStateOutside forRegion:region];
            [[PCFPushClient shared] locationManager:nil didDetermineState:CLRegionStateUnknown forRegion:region];
        });
    });
});

SPEC_END