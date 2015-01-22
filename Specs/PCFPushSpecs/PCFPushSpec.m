//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "Kiwi.h"
#import "PCFPush.h"
#import "PCFPushClientTest.h"
#import "PCFPushErrors.h"
#import "PCFPushSpecsHelper.h"
#import "PCFPushPersistentStorage.h"
#import "PCFPushParameters.h"
#import "PCFPushRegistrationPutRequestData.h"
#import "PCFPushRegistrationPostRequestData.h"
#import "NSURLConnection+PCFPushAsync2Sync.h"
#import "NSURLConnection+PCFBackEndConnection.h"
#import "NSObject+PCFJSONizable.h"

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
        helper = nil;
    });

    describe(@"setting parameters", ^{

        describe(@"empty and nillable parameters", ^{

            __block BOOL succeeded;
            __block void (^successBlock)();
            __block void (^failureBlock)(NSError *error);

            beforeEach(^{
                succeeded = NO;
                [helper setupDefaultPLIST];
                [helper setupSuccessfulAsyncRequestWithBlock:nil];

                successBlock = ^{
                    succeeded = YES;
                };
                failureBlock = ^(NSError *error) {
                    fail(@"should have succeeded");
                };
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

            __block void (^successBlock)();
            __block void (^failureBlock)(NSError *error);

            beforeEach(^{
                [helper setupDefaultPLIST];
                [helper setupSuccessfulAsyncRequestWithBlock:nil];

                successBlock = ^{};
                failureBlock = ^(NSError *error) {};
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
            }) should] raise];
        });

        it(@"should raise an exception if the APNS device token is nil", ^{
            [[theBlock(^{
                [PCFPush registerForPCFPushNotificationsWithDeviceToken:nil tags:[NSSet set] deviceAlias:@"NOT EMPTY" success:nil failure:nil];
            }) should] raise];
        });

        it(@"should raise an exception if the APNS device token is empty", ^{
           [[theBlock(^{
               [PCFPush registerForPCFPushNotificationsWithDeviceToken:@"" tags:[NSSet set] deviceAlias:@"NOT EMPTY" success:nil failure:nil];
           }) should] raise];
        });
    });

    describe(@"updating registration", ^{

        __block NSInteger successCount;
        __block NSInteger updateRegistrationCount;
        __block void (^testBlock)(SEL sel, id newPersistedValue);
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
                void (^failureBlock)(NSError*) = ^(NSError *error) {
                    fail(@"registration failure block executed");
                };

                [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:helper.params.pushTags deviceAlias:helper.params.pushDeviceAlias success:successBlock failure:failureBlock];
            };
        });

        afterEach(^{
            [[theValue(successCount) shouldEventually] equal:theValue(1)];
            [[theValue(updateRegistrationCount) shouldEventually] equal:theValue(1)];
        });

        it(@"should update after the variantUuid changes", ^{
            testBlock(@selector(setVariantUUID:), @"DIFFERENT STRING");
        });

        it(@"should update after the variantUuid is initially set", ^{
            testBlock(@selector(setVariantUUID:), nil);
        });

        it(@"should update after the variantSecret changes", ^{
            testBlock(@selector(setVariantSecret:), @"DIFFERENT STRING");
        });

        it(@"should update after the variantSecret is initially set", ^{
            testBlock(@selector(setVariantSecret:), nil);
        });

        it(@"should update after the deviceAlias changes", ^{
            testBlock(@selector(setDeviceAlias:), @"DIFFERENT STRING");
        });

        it(@"should update after the deviceAlias is initially set", ^{
            testBlock(@selector(setDeviceAlias:), nil);
        });

        it(@"should update after the APNSDeviceToken changes", ^{
            testBlock(@selector(setAPNSDeviceToken:), [@"DIFFERENT TOKEN" dataUsingEncoding:NSUTF8StringEncoding]);
        });

        it(@"should update after the tags change to a different value", ^{
            expectedSubscribeTags = helper.tags1;
            expectedUnsubscribeTags = [NSSet setWithArray:@[ @"DIFFERENT TAG" ]];
            testBlock(@selector(setTags:), expectedUnsubscribeTags);
        });

        it(@"should update after tags initially set from nil", ^{
            expectedSubscribeTags = helper.tags1;
            testBlock(@selector(setTags:), nil);
        });

        it(@"should update after tags initially set from empty", ^{
            expectedSubscribeTags = helper.tags1;
            testBlock(@selector(setTags:), [NSSet set]);
        });

        it(@"should update after tags change to nil", ^{
            helper.params.pushTags = nil;
            expectedUnsubscribeTags = helper.tags1;
            testBlock(@selector(setTags:), helper.tags1);
        });

        it(@"should update after tags change to empty", ^{
            helper.params.pushTags = [NSSet set];
            expectedUnsubscribeTags = helper.tags1;
            testBlock(@selector(setTags:), helper.tags1);
        });
    });

    describe(@"successful registration", ^{

        beforeEach(^{
            [PCFPushClient resetSharedClient];
        });

        it(@"should make a POST request to the server on a new registration", ^{

            __block BOOL wasSuccessBlockExecuted = NO;
            __block NSSet *expectedTags;

            [[NSURLConnection shouldEventually] receive:@selector(sendAsynchronousRequest:queue:completionHandler:) withCount:1];

            [helper setupSuccessfulAsyncRequestWithBlock:^(NSURLRequest *request) {

                [[request.HTTPMethod should] equal:@"POST"];

                NSError *error;
                PCFPushRegistrationPostRequestData *requestBody = [PCFPushRegistrationPostRequestData pcf_fromJSONData:request.HTTPBody error:&error];
                if (error) {
                    fail(@"Could not parse HTTP request body");
                }
                [[requestBody shouldNot] beNil];
                if (expectedTags) {
                    [[[NSSet setWithArray:requestBody.tags] should] equal:expectedTags];
                } else {
                    [[requestBody.tags should] beNil];
                }
            }];

            expectedTags = helper.tags1;
            [PCFPush load];
            [helper setupDefaultPLIST];

            void (^successBlock)() = ^{
                wasSuccessBlockExecuted = YES;
            };

            void (^failureBlock)(NSError *error) = ^(NSError *error) {
                fail(@"registration failure block executed");
            };

            [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:helper.tags1 deviceAlias:TEST_DEVICE_ALIAS success:successBlock failure:failureBlock];
            [[theValue(wasSuccessBlockExecuted) shouldEventually] beTrue];
        });

        it(@"should bypass registering against Remote Push Server if Device Token matches the stored token.", ^{

            __block BOOL wasSuccessBlockExecuted = NO;

            [[NSURLConnection shouldEventually] receive:@selector(sendAsynchronousRequest:queue:completionHandler:) withCount:1];
            [helper setupSuccessfulAsyncRequestWithBlock:^(NSURLRequest *request) {}];

            [PCFPush load];
            [helper setupDefaultPLIST];

            void (^successBlock)() = ^{
                wasSuccessBlockExecuted = YES;
            };

            void (^failureBlock)(NSError *error) = ^(NSError *error) {
                fail(@"registration failure block executed");
            };

            [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:helper.tags1 deviceAlias:TEST_DEVICE_ALIAS success:nil failure:failureBlock];
            [PCFPush load]; // Reset the state in the state engine

            [PCFPush registerForPCFPushNotificationsWithDeviceToken:helper.apnsDeviceToken tags:helper.tags1 deviceAlias:TEST_DEVICE_ALIAS success:successBlock failure:failureBlock];

            [[theValue(wasSuccessBlockExecuted) shouldEventually] beTrue];
        });
    });

    context(@"handling server responses", ^{
        __block BOOL wasExpectedResult = NO;
        __block PCFPushSpecsHelper *helper;

        beforeEach(^{
            helper = [[PCFPushSpecsHelper alloc] init];
            [helper setupParameters];
            wasExpectedResult = NO;
        });

        afterEach(^{
            [[theValue(wasExpectedResult) should] beTrue];
            [helper reset];
            helper = nil;
        });

        it(@"should handle an HTTP status error", ^{
            NSError *error;
            [helper swizzleAsyncRequestWithSelector:@selector(HTTPErrorResponseRequest:queue:completionHandler:) error:&error];

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
            NSError *error;
            [helper swizzleAsyncRequestWithSelector:@selector(emptyDataResponseRequest:queue:completionHandler:) error:&error];

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
            NSError *error;
            [helper swizzleAsyncRequestWithSelector:@selector(nilDataResponseRequest:queue:completionHandler:) error:&error];

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
            NSError *error;
            [helper swizzleAsyncRequestWithSelector:@selector(zeroLengthDataResponseRequest:queue:completionHandler:) error:&error];

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
            NSError *error;
            [helper swizzleAsyncRequestWithSelector:@selector(unparseableDataResponseRequest:queue:completionHandler:) error:&error];

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
            NSError *error;
            [helper swizzleAsyncRequestWithSelector:@selector(missingUUIDResponseRequest:queue:completionHandler:) error:&error];

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

            it(@"should be considered a success if the device isn't currently registered", ^{
                [[[PCFPushPersistentStorage serverDeviceID] should] beNil];
                [[NSURLConnection shouldNotEventually] receive:@selector(sendAsynchronousRequest:queue:completionHandler:)];

                [PCFPush unregisterFromPCFPushNotificationsWithSuccess:^{
                    successBlockExecuted = YES;

                }                                failure:^(NSError *error) {
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

                }                                failure:^(NSError *error) {
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

            }                                failure:^(NSError *error) {
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

            }                                failure:^(NSError *error) {
                failureBlockExecuted = YES;

            }];

            [[theValue(failureBlockExecuted) shouldEventually] beTrue];
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
            __block BOOL wasSuccessBlockCalled;

            beforeEach(^{
                updateRegistrationCount = 0;
                expectedSubscribeTags = nil;
                expectedUnsubscribeTags = nil;
                wasSuccessBlockCalled = NO;

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
                [[theValue(wasSuccessBlockCalled) shouldEventually] beTrue];
            });

            it(@"should be able to register to some new tags", ^{
                expectedSubscribeTags = helper.tags2;
                expectedUnsubscribeTags = helper.tags1;

                [PCFPush subscribeToTags:helper.tags2 success:^{
                    wasSuccessBlockCalled = YES;
                }                failure:^(NSError *error) {
                    fail(@"Should not have failed");
                }];

                [[theValue(updateRegistrationCount) shouldEventually] equal:theValue(1)];
            });

            it(@"should not be called with the same tags", ^{
                [PCFPush subscribeToTags:helper.tags1 success:^{
                    wasSuccessBlockCalled = YES;
                }                failure:^(NSError *error) {
                    fail(@"Should not have failed");
                }];

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

                [PCFPush subscribeToTags:helper.tags2 success:^{
                    fail(@"should not have succeeded");
                }                failure:^(NSError *error) {
                    [[error.domain should] equal:PCFPushErrorDomain];
                    wasFailBlockCalled = YES;
                }];
            });
        });
    });
});

SPEC_END