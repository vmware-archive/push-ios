//
//  PCFPushSDKSpec.m
//  PCFPushSDK
//
//  Created by Rob Szumlakowski on 2014-02-14.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "Kiwi.h"

#import "PCFPushSDK.h"
#import "PCFPushClientTest.h"
#import "PCFPushClient.h"
#import "PCFPushErrors.h"
#import "PCFPushSpecHelper.h"
#import "PCFPersistentStorage+Push.h"
#import "PCFParameters.h"
#import "PCFPushBackEndRegistrationResponseDataTest.h"
#import "NSURLConnection+PCFPushAsync2Sync.h"
#import "NSURLConnection+PCFBackEndConnection.h"

SPEC_BEGIN(PCFPushSDKSpec)

describe(@"PCFPushSDK", ^{
    __block PCFPushSpecHelper *helper = nil;
    __block id<UIApplicationDelegate> previousAppDelegate;
    
    beforeEach(^{
        helper = [[PCFPushSpecHelper alloc] init];
        [helper setupApplication];
        [helper setupApplicationDelegate];
        [helper setupParameters];
        previousAppDelegate = helper.applicationDelegate;
    });
    
    afterEach(^{
        previousAppDelegate = nil;
        [helper reset];
        helper = nil;
    });
    
    describe(@"updating registration", ^{
        
        beforeEach(^{
            [PCFPushClient resetSharedClient];
            [helper setupApplicationForSuccessfulRegistration];
            [helper setupApplicationDelegateForSuccessfulRegistration];
        });
        
        it(@"should handle updating record on the push server when parameters or APNS token change", ^{
            __block NSInteger successCount = 0;
            __block NSInteger registerCount = 0;
            __block NSInteger updateRegistrationCount = 0;
            
            SEL stringSelectors[] = {
                @selector(setVariantUUID:),
                @selector(setReleaseSecret:),
                @selector(setDeviceAlias:),
            };
            
            SEL dataSelectors[] = {
                @selector(setAPNSDeviceToken:),
            };
            
            __block NSInteger stringSelectorsCount = sizeof(stringSelectors)/sizeof(stringSelectors[0]);
            __block NSInteger dataSelectorsCount = sizeof(dataSelectors)/sizeof(dataSelectors[0]);
            
            [[helper.application shouldEventually] receive:@selector(registerForRemoteNotificationTypes:)];
            [[(id)helper.applicationDelegate shouldEventually] receive:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:)];
            [[NSURLConnection shouldEventually] receive:@selector(sendAsynchronousRequest:queue:completionHandler:) withCount:stringSelectorsCount + dataSelectorsCount];
            
            [NSURLConnection stub:@selector(sendAsynchronousRequest:queue:completionHandler:) withBlock:^id(NSArray *params) {
                NSURLRequest *request = params[0];
                
                __block NSData *newData;
                __block NSHTTPURLResponse *newResponse;
                
                if ([request.HTTPMethod isEqualToString:@"DELETE"]) {
                    fail(@"unregistration request made.");
                }
                
                if ([request.HTTPMethod isEqualToString:@"PUT"] || [request.HTTPMethod isEqualToString:@"POST"]) {
                    if ([request.HTTPMethod isEqualToString:@"POST"]) {
                        registerCount++;
                        
                    } else if ([request.HTTPMethod isEqualToString:@"PUT"]) {
                        updateRegistrationCount++;
                    }
                    
                    newResponse = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200 HTTPVersion:nil headerFields:nil];
                    NSDictionary *dict = @{
                                           RegistrationAttributes.deviceOS           : TEST_OS,
                                           RegistrationAttributes.deviceOSVersion    : TEST_OS_VERSION,
                                           RegistrationAttributes.deviceAlias        : TEST_DEVICE_ALIAS,
                                           RegistrationAttributes.deviceManufacturer : TEST_DEVICE_MANUFACTURER,
                                           RegistrationAttributes.deviceModel        : TEST_DEVICE_MODEL,
                                           RegistrationAttributes.variantUUID        : TEST_VARIANT_UUID,
                                           RegistrationAttributes.registrationToken  : TEST_REGISTRATION_TOKEN,
                                           kDeviceUUID                               : TEST_DEVICE_UUID,
                                           };
                    newData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil];
                }
                
                CompletionHandler handler = params[2];
                handler(newResponse, newData, nil);
                return nil;
            }];
            
            NSString *differentValue = @"DIFFERENT_VALUE";
            
            for (NSInteger i = 0; i < dataSelectorsCount; i++) {
                [helper setupDefaultSavedParameters];
                
                [PCFPersistentStorage performSelector:stringSelectors[i] withObject:[differentValue dataUsingEncoding:NSUTF8StringEncoding]];
                [PCFPushSDK setRegistrationParameters:helper.params];
                [PCFPushSDK setCompletionBlockWithSuccess:^{
                    successCount++;
                } failure:^(NSError *error) {
                    fail(@"registration failure block executed");
                }];
                
                [PCFPushSDK registerForPushNotifications];
            }
            
            for (NSInteger i = 0; i < stringSelectorsCount; i++) {
                [helper setupDefaultSavedParameters];
                
                [PCFPersistentStorage performSelector:stringSelectors[i] withObject:differentValue];
                [PCFPushSDK setRegistrationParameters:helper.params];
                [PCFPushSDK setCompletionBlockWithSuccess:^{
                    successCount++;
                } failure:^(NSError *error) {
                    fail(@"registration failure block executed");
                }];
            }
            
            [[theValue(successCount) shouldEventually] equal:theValue(stringSelectorsCount + dataSelectorsCount)];
            [[theValue(updateRegistrationCount) shouldEventually] equal:theValue(stringSelectorsCount + dataSelectorsCount)];
            [[theValue(registerCount) shouldEventually] equal:theValue(0)];
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
            [[helper.application shouldEventually] receive:@selector(registerForRemoteNotificationTypes:) withCount:2];
            [[(id)helper.applicationDelegate shouldEventually] receive:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:) withCount:2];
            [[NSURLConnection shouldEventually] receive:@selector(sendAsynchronousRequest:queue:completionHandler:) withCount:1];
            
            [NSURLConnection stub:@selector(sendAsynchronousRequest:queue:completionHandler:) withBlock:^id(NSArray *params) {
                NSURLRequest *request = params[0];
                
                __block NSData *newData;
                __block NSHTTPURLResponse *newResponse;
                
                if ([request.HTTPMethod isEqualToString:@"PUT"] || [request.HTTPMethod isEqualToString:@"POST"]) {
                    newResponse = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200 HTTPVersion:nil headerFields:nil];
                    NSDictionary *dict = @{
                                           RegistrationAttributes.deviceOS           : TEST_OS,
                                           RegistrationAttributes.deviceOSVersion    : TEST_OS_VERSION,
                                           RegistrationAttributes.deviceAlias        : TEST_DEVICE_ALIAS,
                                           RegistrationAttributes.deviceManufacturer : TEST_DEVICE_MANUFACTURER,
                                           RegistrationAttributes.deviceModel        : TEST_DEVICE_MODEL,
                                           RegistrationAttributes.variantUUID        : TEST_VARIANT_UUID,
                                           RegistrationAttributes.registrationToken  : TEST_REGISTRATION_TOKEN,
                                           kDeviceUUID                               : TEST_DEVICE_UUID,
                                           };
                    newData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil];
                }
                
                CompletionHandler handler = params[2];
                handler(newResponse, newData, nil);
                return nil;
            }];
            
            [PCFPushSDK load];
            [PCFPushSDK setRegistrationParameters:helper.params];
            [PCFPushSDK setCompletionBlockWithSuccess:^{
                successBlockExecuted = YES;
            }
                                              failure:^(NSError *error) {
                                                  fail(@"registration failure block executed");
                                              }];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidFinishLaunchingNotification object:nil];
            [[theValue(successBlockExecuted) shouldEventually] beTrue];
            successBlockExecuted = NO;
            [PCFPushSDK load];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidFinishLaunchingNotification object:nil];
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
            [[[PCFPersistentStorage APNSDeviceToken] should] beNil];
            expectedResult = NO;
            testError = nil;
        });
        
        it(@"should handle registration failures from APNS", ^{
            [PCFPushSDK load];
            
            [[helper.application shouldEventually] receive:@selector(registerForRemoteNotificationTypes:)];
            [[(id)helper.applicationDelegate shouldEventually] receive:@selector(application:didFailToRegisterForRemoteNotificationsWithError:)];
            
            [PCFPushSDK setRegistrationParameters:helper.params];
            [PCFPushSDK setCompletionBlockWithSuccess:nil
                                              failure:^(NSError *error) {
                                                  expectedResult = YES;
                                              }];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidFinishLaunchingNotification object:nil];
        });
    });
    
    context(@"valid object arguements", ^{
        __block BOOL wasExpectedResult = NO;
        __block PCFPushSpecHelper *helper;
        
        beforeEach(^{
            helper = [[PCFPushSpecHelper alloc] init];
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
            [helper setupDefaultSavedParameters];
            successBlockExecuted = NO;
            
            [NSURLConnection stub:@selector(sendAsynchronousRequest:queue:completionHandler:) withBlock:^id(NSArray *params) {
                NSURLRequest *request = params[0];
                
                __block NSHTTPURLResponse *newResponse;
                
                if ([request.HTTPMethod isEqualToString:@"DELETE"]) {
                    newResponse = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:204 HTTPVersion:nil headerFields:nil];
                }
                
                CompletionHandler handler = params[2];
                handler(newResponse, nil, nil);
                return nil;
            }];
        });
        
        afterEach(^{
            SEL selectors[] = {
                @selector(APNSDeviceToken),
                @selector(serverDeviceID),
                @selector(variantUUID),
                @selector(deviceAlias),
            };
            
            for (NSUInteger i = 0; i < sizeof(selectors)/sizeof(selectors[0]); i++) {
                [[[PCFPersistentStorage performSelector:selectors[i]] should] beNil];
            }
        });
        
        it(@"should succesfully unregister if the device has a persisted backEndDeviceUUID and should remove all persisted parameters when unregister is successful", ^{
            [[[PCFPersistentStorage serverDeviceID] shouldNot] beNil];
            [[NSURLConnection shouldEventually] receive:@selector(sendAsynchronousRequest:queue:completionHandler:)];
            
            [PCFPushSDK unregisterWithPushServerSuccess:^{
                successBlockExecuted = YES;
                
            } failure:^(NSError *error) {
                fail(@"unregistration failure block executed");
            }];
            
            [[theValue(successBlockExecuted) shouldEventually] beTrue];
        });
    });
    
    describe(@"unsuccessful unregistration when device not registered on push server", ^{
        __block BOOL failureBlockExecuted = NO;
        
        beforeEach(^{
            [helper setupDefaultSavedParameters];
            
            [NSURLConnection stub:@selector(sendAsynchronousRequest:queue:completionHandler:) withBlock:^id(NSArray *params) {
                NSURLRequest *request = params[0];
                
                __block NSHTTPURLResponse *newResponse;
                
                if ([request.HTTPMethod isEqualToString:@"DELETE"]) {
                    newResponse = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:404 HTTPVersion:nil headerFields:nil];
                }
                
                CompletionHandler handler = params[2];
                handler(newResponse, nil, nil);
                return nil;
            }];
        });
        
        it(@"should perform failure block if server responds with a 404 (DeviceUUID not registered on server) ", ^{
            
            [[NSURLConnection shouldEventually] receive:@selector(sendAsynchronousRequest:queue:completionHandler:)];
            
            [PCFPushSDK unregisterWithPushServerSuccess:^{
                fail(@"unregistration success block executed");
                
            } failure:^(NSError *error) {
                failureBlockExecuted = YES;
                
            }];
            
            [[theValue(failureBlockExecuted) shouldEventually] beTrue];
        });
        
    });
    
    describe(@"unsuccessful unregistration", ^{
        __block BOOL failureBlockExecuted = NO;
        
        beforeEach(^{
            [helper setupDefaultSavedParameters];
            failureBlockExecuted = NO;
            
            [NSURLConnection stub:@selector(sendAsynchronousRequest:queue:completionHandler:) withBlock:^id(NSArray *params) {
                NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:nil];
                CompletionHandler handler = params[2];
                handler(nil, nil, error);
                return nil;
            }];
        });
        
        it(@"should perform failure block if server request returns error", ^{
            [[NSURLConnection shouldEventually] receive:@selector(sendAsynchronousRequest:queue:completionHandler:)];
            
            [PCFPushSDK unregisterWithPushServerSuccess:^{
                fail(@"unregistration success block executed incorrectly");
                
            } failure:^(NSError *error) {
                failureBlockExecuted = YES;
                
            }];
            
            [[theValue(failureBlockExecuted) shouldEventually] beTrue];
        });
    });
});

SPEC_END
