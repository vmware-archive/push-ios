//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "Kiwi.h"

#import "PCFPush.h"
#import "PCFPushClientTest.h"
#import "PCFPushErrors.h"
#import "PCFPushSpecsHelper.h"
#import "PCFPushPersistentStorage.h"
#import "PCFParameters.h"
#import "PCFPushBackEndRegistrationResponseDataTest.h"
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
        [helper setupApplication];
        [helper setupApplicationDelegate];
        [helper setupParameters];
    });
    
    afterEach(^{
        [helper reset];
        helper = nil;
    });
    
    describe(@"setting parameters", ^{

        describe(@"empty and nillable parameters", ^{

            __block BOOL succeeded;

            beforeEach(^{
                succeeded = NO;
                [helper setupApplicationForSuccessfulRegistration];
                [helper setupApplicationDelegateForSuccessfulRegistration];
                [helper setupDefaultPLIST:helper.params];
                [helper setupSuccessfulAsyncRequestWithBlock:nil];

                [PCFPush setCompletionBlockWithSuccess:^{
                    succeeded = YES;
                } failure:^(NSError *error) {
                    fail(@"Should have succeeded");
                }];
                [PCFPush registerForPushNotifications];
            });

            afterEach(^{
                [[theValue(succeeded) shouldEventually] equal:theValue(YES)];
            });

            it(@"should accept a nil deviceAlias", ^{
                [PCFPush setDeviceAlias:nil];
            });

            it(@"should accept an empty deviceAlias", ^{
                [PCFPush setDeviceAlias:@""];
            });

            it(@"should accept a non-empty deviceAlias", ^{
                [PCFPush setDeviceAlias:@"NOT EMPTY"];
            });

            it(@"should accept a nil tags", ^{
                [PCFPush setTags:nil];
            });

            it(@"should accept an empty tags", ^{
                [PCFPush setTags:[NSSet set]];
            });

            it(@"should accept a non-empty tags", ^{
                [PCFPush setTags:helper.tags2];
            });
        });

        it(@"should raise an exception if parameters are nil", ^{
            [[theBlock(^{
                [helper setupDefaultPLIST:nil];
                [PCFPush registerForPushNotifications];
            }) should] raiseWithName:NSInvalidArgumentException];
        });

        it(@"should raise an exception if parameters are invalid", ^{
            helper.params.productionPushVariantUUID = nil;
            [[theBlock(^{
                [helper setupDefaultPLIST:helper.params];
                [PCFPush registerForPushNotifications];
            }) should] raiseWithName:NSInvalidArgumentException];
        });
        
        it(@"should raise an exception if startRegistration is called without parameters being set", ^{
            [[theBlock(^{
                [PCFPush registerForPushNotifications];
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
            
            [helper setupApplicationForSuccessfulRegistration];
            [helper setupApplicationDelegateForSuccessfulRegistration];
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

            [[NSURLConnection shouldEventually] receive:@selector(sendAsynchronousRequest:queue:completionHandler:)];
            [[(id)helper.applicationDelegate shouldEventually] receive:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:) withCount:1];

            testBlock = ^(SEL sel, id newPersistedValue) {
                
                [helper setupDefaultPersistedParameters];
                [helper setupDefaultPLIST:helper.params];

                [PCFPushPersistentStorage performSelector:sel withObject:newPersistedValue];
                
                [PCFPush setCompletionBlockWithSuccess:^{
                    successCount++;
                }                              failure:^(NSError *error) {
                    fail(@"registration failure block executed");
                }];

                [PCFPush registerForPushNotifications];
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
            [helper setupApplicationForSuccessfulRegistration];
            [helper setupApplicationDelegateForSuccessfulRegistration];
        });
        
        it(@"should bypass registering against Remote Push Server if Device Token matches the stored token.", ^{
            
            __block BOOL successBlockExecuted = NO;
            __block NSSet *expectedTags;
            
            [[(id)helper.applicationDelegate shouldEventually] receive:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:) withCount:2];
            [[NSURLConnection shouldEventually] receive:@selector(sendAsynchronousRequest:queue:completionHandler:) withCount:1];

            [helper setupSuccessfulAsyncRequestWithBlock:^(NSURLRequest *request) {
                if (![request.HTTPMethod isEqualToString:@"POST"]) {
                    fail(@"Request must be a POST");
                }

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
            [helper setupDefaultPLIST:helper.params];
            [PCFPush setCompletionBlockWithSuccess:^{
                successBlockExecuted = YES;
            }                              failure:^(NSError *error) {
                fail(@"registration failure block executed");
            }];

            [PCFPush registerForPushNotifications];
            [[theValue(successBlockExecuted) shouldEventually] beTrue];
            successBlockExecuted = NO;
            [PCFPush load];
            
            [PCFPush registerForPushNotifications];
            [[theValue(successBlockExecuted) shouldEventually] beTrue];
        });
    });
    
    describe(@"failed registration", ^{
        
        __block NSError *testError;
        __block BOOL expectedResult = NO;
        
        beforeEach(^{
            [PCFPushClient resetSharedClient];
            
            testError = [NSError errorWithDomain:@"Some boring error" code:0 userInfo:nil];
            [helper setupApplicationForFailedRegistrationWithError:testError];
            [helper setupApplicationDelegateForFailedRegistrationWithError:testError];
            expectedResult = NO;
        });
        
        afterEach(^{
            [[theValue(expectedResult) should] beTrue];
            [[[PCFPushPersistentStorage APNSDeviceToken] should] beNil];
            expectedResult = NO;
            testError = nil;
        });
        
        it(@"should handle registration failures from APNS", ^{
            [PCFPush load];
            
            [[(id)helper.applicationDelegate shouldEventually] receive:@selector(application:didFailToRegisterForRemoteNotificationsWithError:)];

            [helper setupDefaultPLIST:helper.params];
            [PCFPush setCompletionBlockWithSuccess:nil
                                           failure:^(NSError *error) {
                                               expectedResult = YES;
                                           }];
            
            [PCFPush registerForPushNotifications];
        });
    });
    
    context(@"valid object arguments", ^{
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
                
                [PCFPush unregisterWithPushServerSuccess:^{
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
                
                [PCFPush unregisterWithPushServerSuccess:^{
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
            
            [PCFPush unregisterWithPushServerSuccess:^{
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
            
            [PCFPush unregisterWithPushServerSuccess:^{
                fail(@"unregistration success block executed incorrectly");

            }                                failure:^(NSError *error) {
                failureBlockExecuted = YES;

            }];
            
            [[theValue(failureBlockExecuted) shouldEventually] beTrue];
        });
    });
});

SPEC_END
