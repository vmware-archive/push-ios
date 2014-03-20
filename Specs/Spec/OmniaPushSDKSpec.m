//
//  OmniaPushSDKSpec.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-02-14.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "Kiwi.h"

#import "OmniaPushSDKTest.h"
#import "OmniaPushErrors.h"
#import "OmniaSpecHelper.h"
#import "OmniaPushPersistentStorage.h"
#import "OmniaFakeOperationQueue.h"
#import "OmniaPushRegistrationParameters.h"
#import "NSURLConnection+OmniaAsync2Sync.h"

SPEC_BEGIN(OmniaPushSDKSpec)

describe(@"OmniaPushSDK", ^{
    __block OmniaSpecHelper *helper = nil;
    __block id<UIApplicationDelegate> previousAppDelegate;
    __block UIRemoteNotificationType testNotificationTypes = TEST_NOTIFICATION_TYPES;
    
    beforeEach(^{
        helper = [[OmniaSpecHelper alloc] init];
        [helper setupApplication];
        [helper setupApplicationDelegate];
        [helper setupParametersWithNotificationTypes:testNotificationTypes];
        [helper setupQueues];
        [OmniaPushSDK setWorkerQueue:helper.workerQueue];
        previousAppDelegate = helper.applicationDelegate;
    });
    
    afterEach(^{
        previousAppDelegate = nil;
        [helper reset];
        helper = nil;
    });
    
    describe(@"registration with bad arguments", ^{
        
        beforeEach(^{
            [helper setupApplicationForSuccessfulRegistrationWithNotificationTypes:testNotificationTypes];
            [helper setupApplicationDelegateForSuccessfulRegistration];
        });
                   
        it(@"should require a parameters object", ^{
            __block BOOL blockExecuted = NO;
            [[theBlock(^{[OmniaPushSDK registerWithParameters:nil success:^(NSURLResponse *response, id responseObject) {
                blockExecuted = YES;
            } failure:^(NSURLResponse *response, NSError *error) {
                blockExecuted = YES;
            }];})
              should] raise];
            [[theValue(blockExecuted) should] beFalse];
            
            [[theBlock(^{[OmniaPushSDK registerWithParameters:nil];})
              should] raise];
        });
    });

    describe(@"successful registration", ^{
        
        __block BOOL expectedResult = NO;
        
        beforeEach(^{
            [helper setupApplicationForSuccessfulRegistrationWithNotificationTypes:testNotificationTypes];
            [helper setupApplicationDelegateForSuccessfulRegistration];
            
            [[helper.application shouldEventually] receive:@selector(registerForRemoteNotificationTypes:)];
            [[(id)helper.applicationDelegate shouldEventually] receive:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:)];
            
            NSError *error;
            [helper swizzleAsyncRequestWithSelector:@selector(successfulRequest:queue:completionHandler:) error:&error];
            [[error should] beNil];
            
            expectedResult = NO;
        });
        
        afterEach(^{
            [[theValue(expectedResult) should] beTrue];
            expectedResult = NO;
        });
        
        it(@"should handle successful registrations from APNS", ^{
            [OmniaPushSDK registerWithParameters:helper.params
                                         success:^(NSURLResponse *response, id responseObject) {
                                             expectedResult = YES;
                                         }
                                         failure:^(NSURLResponse *response, NSError *error) {
                                             expectedResult = NO;
                                         }];
        });
        
        it(@"should unregister from back end if APNSDeviceToken does not match locally stored version", ^{
            NSData *deviceToken1 = [@"DIFFERENT TEST DEVICE TOKEN" dataUsingEncoding:NSUTF8StringEncoding];
            [OmniaPushPersistentStorage setAPNSDeviceToken:deviceToken1];
            
            NSError *error;
            [helper swizzleAsyncRequestWithSelector:@selector(successfulRequest:queue:completionHandler:) error:&error];
            [[error should] beNil];
            
            [OmniaPushSDK registerWithParameters:helper.params
                                         success:^(NSURLResponse *response, id responseObject) {
                                             expectedResult = YES;
                                         }
                                         failure:^(NSURLResponse *response, NSError *error) {
                                             expectedResult = NO;
                                         }];
        });
    });
    
    describe(@"failed registration", ^{

        __block NSError *testError;
        __block BOOL expectedResult = NO;

        beforeEach(^{
            testError = [NSError errorWithDomain:@"Some boring error" code:0 userInfo:nil];
            [helper setupApplicationForFailedRegistrationWithNotificationTypes:TEST_NOTIFICATION_TYPES error:testError];
            [helper setupApplicationDelegateForFailedRegistrationWithError:testError];
            expectedResult = NO;
        });
        
        afterEach(^{
            [[theValue(expectedResult) should] beTrue];
            [[[OmniaPushPersistentStorage APNSDeviceToken] should] beNil];
            expectedResult = NO;
            testError = nil;
        });
        
        it(@"should handle registration failures from APNS", ^{
            [[helper.application shouldEventually] receive:@selector(registerForRemoteNotificationTypes:)];
            [[(id)helper.applicationDelegate shouldEventually] receive:@selector(application:didFailToRegisterForRemoteNotificationsWithError:)];

            [OmniaPushSDK registerWithParameters:helper.params
                                         success:nil
                                         failure:^(NSURLResponse *response, NSError *error) {
                                             expectedResult = YES;
                                         }];
        });
    });
    
    context(@"valid object arguements", ^{
        __block BOOL wasExpectedResult = NO;
        __block OmniaSpecHelper *helper;
        
        beforeEach(^{
            helper = [[OmniaSpecHelper alloc] init];
            [helper setupParametersWithNotificationTypes:TEST_NOTIFICATION_TYPES];
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
            
            [OmniaPushSDK sendRegisterRequestWithParameters:helper.params
                                                   devToken:helper.apnsDeviceToken
                                               successBlock:^(NSURLResponse *response, id responseObject) {
                                                   wasExpectedResult = NO;
                                               }
                                               failureBlock:^(NSURLResponse *response, NSError *error) {
                                                   [[error.domain should] equal:OmniaPushErrorDomain];
                                                   [[theValue(error.code) should] equal:theValue(OmniaPushBackEndRegistrationFailedHTTPStatusCode)];
                                                   wasExpectedResult = YES;
                                               }];
        });

        
        it(@"should handle a successful response with empty data", ^{
            NSError *error;
            [helper swizzleAsyncRequestWithSelector:@selector(emptyDataResponseRequest:queue:completionHandler:) error:&error];
            
            [OmniaPushSDK sendRegisterRequestWithParameters:helper.params
                                                   devToken:helper.apnsDeviceToken
                                               successBlock:^(NSURLResponse *response, id responseObject) {
                                                   wasExpectedResult = NO;
                                               }
                                               failureBlock:^(NSURLResponse *response, NSError *error) {
                                                   [[error.domain should] equal:OmniaPushErrorDomain];
                                                   [[theValue(error.code) should] equal:theValue(OmniaPushBackEndRegistrationEmptyResponseData)];
                                                   wasExpectedResult = YES;
                                               }];
        });
        
        it(@"should handle a successful response with nil data", ^{
            NSError *error;
            [helper swizzleAsyncRequestWithSelector:@selector(nilDataResponseRequest:queue:completionHandler:) error:&error];
            
            [OmniaPushSDK sendRegisterRequestWithParameters:helper.params
                                                   devToken:helper.apnsDeviceToken
                                               successBlock:^(NSURLResponse *response, id responseObject) {
                                                   wasExpectedResult = NO;
                                               }
                                               failureBlock:^(NSURLResponse *response, NSError *error) {
                                                   [[error.domain should] equal:OmniaPushErrorDomain];
                                                   [[theValue(error.code) should] equal:theValue(OmniaPushBackEndRegistrationEmptyResponseData)];
                                                   wasExpectedResult = YES;
                                               }];
        });
        
        it(@"should handle a successful response with zero-length", ^{
            NSError *error;
            [helper swizzleAsyncRequestWithSelector:@selector(zeroLengthDataResponseRequest:queue:completionHandler:) error:&error];
            
            [OmniaPushSDK sendRegisterRequestWithParameters:helper.params
                                                   devToken:helper.apnsDeviceToken
                                               successBlock:^(NSURLResponse *response, id responseObject) {
                                                   wasExpectedResult = NO;
                                               }
                                               failureBlock:^(NSURLResponse *response, NSError *error) {
                                                   [[error.domain should] equal:OmniaPushErrorDomain];
                                                   [[theValue(error.code) should] equal:theValue(OmniaPushBackEndRegistrationEmptyResponseData)];
                                                   wasExpectedResult = YES;
                                               }];
        });
        
        it(@"should handle a successful response that contains unparseable text", ^{
            NSError *error;
            [helper swizzleAsyncRequestWithSelector:@selector(unparseableDataResponseRequest:queue:completionHandler:) error:&error];
            
            [OmniaPushSDK sendRegisterRequestWithParameters:helper.params
                                                   devToken:helper.apnsDeviceToken
                                               successBlock:^(NSURLResponse *response, id responseObject) {
                                                   wasExpectedResult = NO;
                                               }
                                               failureBlock:^(NSURLResponse *response, NSError *error) {
                                                   [[error shouldNot] beNil];
                                                   wasExpectedResult = YES;
                                               }];
        });
        
        it(@"should require a device_uuid in the server response", ^{
            NSError *error;
            [helper swizzleAsyncRequestWithSelector:@selector(missingUUIDResponseRequest:queue:completionHandler:) error:&error];
            
            [OmniaPushSDK sendRegisterRequestWithParameters:helper.params
                                                   devToken:helper.apnsDeviceToken
                                               successBlock:^(NSURLResponse *response, id responseObject) {
                                                   wasExpectedResult = NO;
                                               }
                                               failureBlock:^(NSURLResponse *response, NSError *error) {
                                                   wasExpectedResult = YES;
                                                   [[error.domain should] equal:OmniaPushErrorDomain];
                                                   [[theValue(error.code) should] equal:theValue(OmniaPushBackEndRegistrationResponseDataNoDeviceUuid)];
                                               }];
        });
        
    });
});

SPEC_END
