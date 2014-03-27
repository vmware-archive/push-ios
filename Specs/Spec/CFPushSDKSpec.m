//
//  CFPushSDKSpec.m
//  CFPushSDK
//
//  Created by Rob Szumlakowski on 2014-02-14.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "Kiwi.h"

#import "CFPushSDKTest.h"
#import "CFPushErrors.h"
#import "CFSpecHelper.h"
#import "CFPushPersistentStorage.h"
#import "CFPushParameters.h"
#import "CFPushBackEndRegistrationResponseDataTest.h"
#import "NSURLConnection+CFAsync2Sync.h"

SPEC_BEGIN(CFPushSDKSpec)

typedef void (^Handler)(NSURLResponse *response, NSData *data, NSError *connectionError);

describe(@"CFPushSDK", ^{
    __block CFSpecHelper *helper = nil;
    __block id<UIApplicationDelegate> previousAppDelegate;
    __block UIRemoteNotificationType testNotificationTypes = TEST_NOTIFICATION_TYPES;
    
    beforeEach(^{
        helper = [[CFSpecHelper alloc] init];
        [helper setupApplication];
        [helper setupApplicationDelegate];
        [helper setupParametersWithNotificationTypes:testNotificationTypes];
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
            [[theBlock(^{[CFPushSDK registerWithParameters:nil
                                                      success:^{
                                                          blockExecuted = YES;
                                                      }
                                                      failure:^(NSError *error) {
                                                          blockExecuted = YES;
                                                      }];})
              should] raise];
            [[theValue(blockExecuted) should] beFalse];
        });
    });

    describe(@"successful registration", ^{
        
        beforeEach(^{
            [helper setupApplicationForSuccessfulRegistrationWithNotificationTypes:testNotificationTypes];
            [helper setupApplicationDelegateForSuccessfulRegistration];
        });
        
        it(@"should handle successfully unregister betfore registering against APNS", ^{
            __block NSInteger successCount = 0;
            __block NSInteger registrationCount = 0;
            __block NSInteger unregistrationCount = 0;
            __block NSInteger selectorsCount = 0;
            
            SEL selectors[] = {
                @selector(setAPNSDeviceToken:),
                @selector(setReleaseUUID:),
                @selector(setReleaseSecret:),
                @selector(setDeviceAlias:),
            };
            
            selectorsCount = sizeof(selectors)/sizeof(selectors[0]);
            
            [[helper.application shouldEventually] receive:@selector(registerForRemoteNotificationTypes:) withCount:selectorsCount];
            [[(id)helper.applicationDelegate shouldEventually] receive:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:) withCount:selectorsCount];
            [[NSURLConnection shouldEventually] receive:@selector(sendAsynchronousRequest:queue:completionHandler:) withCount:selectorsCount*2];
            
            [NSURLConnection stub:@selector(sendAsynchronousRequest:queue:completionHandler:) withBlock:^id(NSArray *params) {
                NSURLRequest *request = params[0];
                
                __block NSData *newData;
                __block NSHTTPURLResponse *newResponse;
                
                if ([request.HTTPMethod isEqualToString:@"DELETE"]) {
                    unregistrationCount++;
                    newResponse = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:204 HTTPVersion:nil headerFields:nil];
                    
                } else if ([request.HTTPMethod isEqualToString:@"POST"]) {
                    newResponse = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200 HTTPVersion:nil headerFields:nil];
                    NSDictionary *dict = @{
                                           kDeviceOS : TEST_OS,
                                           kDeviceOSVersion : TEST_OS_VERSION,
                                           kDeviceUUID : TEST_DEVICE_UUID,
                                           kDeviceAlias : TEST_DEVICE_ALIAS,
                                           kDeviceManufacturer : TEST_DEVICE_MANUFACTURER,
                                           kDeviceModel : TEST_DEVICE_MODEL,
                                           kReleaseUUID : TEST_RELEASE_UUID,
                                           kRegistrationToken : TEST_REGISTRATION_TOKEN,
                                           };
                    newData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil];

                    registrationCount++;
                }
        
                Handler handler = params[2];
                handler(newResponse, newData, nil);
                return nil;
            }];
            
            for (NSInteger i = 0; i < selectorsCount; i++) {
                [CFPushSDK load];
                
                [helper setupDefaultSavedParameters];
                [CFPushPersistentStorage performSelector:selectors[i] withObject:@"DIFFERENT_VALUE"];
                
                [CFPushSDK registerWithParameters:helper.params
                                             success:^ {
                                                 successCount++;
                                             }
                                             failure:^(NSError *error) {
                                                 fail(@"registration failure block executed");
                                             }];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidFinishLaunchingNotification object:nil];
            }
            
            [[theValue(successCount) shouldEventually] equal:theValue(selectorsCount)];
            [[theValue(registrationCount) shouldEventually] equal:theValue(selectorsCount)];
            [[theValue(unregistrationCount) shouldEventually] equal:theValue(selectorsCount)];
        });
        
        it(@"should bypass unregistering if not required before registering against APNS", ^{
            
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
            [[[CFPushPersistentStorage APNSDeviceToken] should] beNil];
            expectedResult = NO;
            testError = nil;
        });
        
        it(@"should handle registration failures from APNS", ^{
            [CFPushSDK load];
            
            [[helper.application shouldEventually] receive:@selector(registerForRemoteNotificationTypes:)];
            [[(id)helper.applicationDelegate shouldEventually] receive:@selector(application:didFailToRegisterForRemoteNotificationsWithError:)];

            [CFPushSDK registerWithParameters:helper.params
                                         success:nil
                                         failure:^(NSError *error) {
                                             expectedResult = YES;
                                         }];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidFinishLaunchingNotification object:nil];
        });
    });
    
    context(@"valid object arguements", ^{
        __block BOOL wasExpectedResult = NO;
        __block CFSpecHelper *helper;
        
        beforeEach(^{
            helper = [[CFSpecHelper alloc] init];
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
            
            [CFPushSDK sendRegisterRequestWithParameters:helper.params
                                                   devToken:helper.apnsDeviceToken
                                               successBlock:^{
                                                   wasExpectedResult = NO;
                                               }
                                               failureBlock:^(NSError *error) {
                                                   [[error.domain should] equal:CFPushErrorDomain];
                                                   [[theValue(error.code) should] equal:theValue(CFPushBackEndRegistrationFailedHTTPStatusCode)];
                                                   wasExpectedResult = YES;
                                               }];
        });

        
        it(@"should handle a successful response with empty data", ^{
            NSError *error;
            [helper swizzleAsyncRequestWithSelector:@selector(emptyDataResponseRequest:queue:completionHandler:) error:&error];
            
            [CFPushSDK sendRegisterRequestWithParameters:helper.params
                                                   devToken:helper.apnsDeviceToken
                                               successBlock:^{
                                                   wasExpectedResult = NO;
                                               }
                                               failureBlock:^(NSError *error) {
                                                   [[error.domain should] equal:CFPushErrorDomain];
                                                   [[theValue(error.code) should] equal:theValue(CFPushBackEndRegistrationEmptyResponseData)];
                                                   wasExpectedResult = YES;
                                               }];
        });
        
        it(@"should handle a successful response with nil data", ^{
            NSError *error;
            [helper swizzleAsyncRequestWithSelector:@selector(nilDataResponseRequest:queue:completionHandler:) error:&error];
            
            [CFPushSDK sendRegisterRequestWithParameters:helper.params
                                                   devToken:helper.apnsDeviceToken
                                               successBlock:^{
                                                   wasExpectedResult = NO;
                                               }
                                               failureBlock:^(NSError *error) {
                                                   [[error.domain should] equal:CFPushErrorDomain];
                                                   [[theValue(error.code) should] equal:theValue(CFPushBackEndRegistrationEmptyResponseData)];
                                                   wasExpectedResult = YES;
                                               }];
        });
        
        it(@"should handle a successful response with zero-length", ^{
            NSError *error;
            [helper swizzleAsyncRequestWithSelector:@selector(zeroLengthDataResponseRequest:queue:completionHandler:) error:&error];
            
            [CFPushSDK sendRegisterRequestWithParameters:helper.params
                                                   devToken:helper.apnsDeviceToken
                                               successBlock:^{
                                                   wasExpectedResult = NO;
                                               }
                                               failureBlock:^(NSError *error) {
                                                   [[error.domain should] equal:CFPushErrorDomain];
                                                   [[theValue(error.code) should] equal:theValue(CFPushBackEndRegistrationEmptyResponseData)];
                                                   wasExpectedResult = YES;
                                               }];
        });
        
        it(@"should handle a successful response that contains unparseable text", ^{
            NSError *error;
            [helper swizzleAsyncRequestWithSelector:@selector(unparseableDataResponseRequest:queue:completionHandler:) error:&error];
            
            [CFPushSDK sendRegisterRequestWithParameters:helper.params
                                                   devToken:helper.apnsDeviceToken
                                               successBlock:^{
                                                   wasExpectedResult = NO;
                                               }
                                               failureBlock:^(NSError *error) {
                                                   [[error shouldNot] beNil];
                                                   wasExpectedResult = YES;
                                               }];
        });
        
        it(@"should require a device_uuid in the server response", ^{
            NSError *error;
            [helper swizzleAsyncRequestWithSelector:@selector(missingUUIDResponseRequest:queue:completionHandler:) error:&error];
            
            [CFPushSDK sendRegisterRequestWithParameters:helper.params
                                                   devToken:helper.apnsDeviceToken
                                               successBlock:^{
                                                   wasExpectedResult = NO;
                                               }
                                               failureBlock:^(NSError *error) {
                                                   wasExpectedResult = YES;
                                                   [[error.domain should] equal:CFPushErrorDomain];
                                                   [[theValue(error.code) should] equal:theValue(CFPushBackEndRegistrationResponseDataNoDeviceUuid)];
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
                
                Handler handler = params[2];
                handler(newResponse, nil, nil);
                return nil;
            }];
        });
        
        afterEach(^{
            SEL selectors[] = {
                @selector(APNSDeviceToken),
                @selector(backEndDeviceID),
                @selector(releaseUUID),
                @selector(deviceAlias),
            };
            
            for (NSUInteger i = 0; i < sizeof(selectors)/sizeof(selectors[0]); i++) {
                [[[CFPushPersistentStorage performSelector:selectors[i]] should] beNil];
            }
        });
        
        it(@"should succesfully unregister if the device has a persisted backEndDeviceUUID and should remove all persisted parameters when unregister is successful", ^{
            [[[CFPushPersistentStorage backEndDeviceID] shouldNot] beNil];
            [[NSURLConnection shouldEventually] receive:@selector(sendAsynchronousRequest:queue:completionHandler:)];
            
            [CFPushSDK unregisterSuccess:^{
                successBlockExecuted = YES;
                
            } failure:^(NSError *error) {
                fail(@"unregistration failure block executed");
            }];
            
            [[theValue(successBlockExecuted) shouldEventually] beTrue];
        });
    });
    
    describe(@"successful unregistration when not registered on push server", ^{
        __block BOOL successBlockExecuted = NO;
        
        beforeEach(^{
            [helper setupDefaultSavedParameters];
            
            [NSURLConnection stub:@selector(sendAsynchronousRequest:queue:completionHandler:) withBlock:^id(NSArray *params) {
                NSURLRequest *request = params[0];
                
                __block NSHTTPURLResponse *newResponse;
                
                if ([request.HTTPMethod isEqualToString:@"DELETE"]) {
                    newResponse = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:404 HTTPVersion:nil headerFields:nil];
                }
                
                Handler handler = params[2];
                handler(newResponse, nil, nil);
                return nil;
            }];
        });
        
        it(@"should perform success block if server responds with a 404 (DeviceUUID not registered on server) ", ^{
            
            [[NSURLConnection shouldEventually] receive:@selector(sendAsynchronousRequest:queue:completionHandler:)];
            
            [CFPushSDK unregisterSuccess:^{
                successBlockExecuted = YES;
                
            } failure:^(NSError *error) {
                fail(@"unregistration failure block executed");
            }];

            [[theValue(successBlockExecuted) shouldEventually] beTrue];
        });
    });

    describe(@"unsuccessful unregistration", ^{
        __block BOOL failureBlockExecuted = NO;
        
        beforeEach(^{
            [helper setupDefaultSavedParameters];
            failureBlockExecuted = NO;
            
            [NSURLConnection stub:@selector(sendAsynchronousRequest:queue:completionHandler:) withBlock:^id(NSArray *params) {
                NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:nil];
                Handler handler = params[2];
                handler(nil, nil, error);
                return nil;
            }];
        });
        
        it(@"should perform failure block if server request returns error", ^{
            [[NSURLConnection shouldEventually] receive:@selector(sendAsynchronousRequest:queue:completionHandler:)];
            
            [CFPushSDK unregisterSuccess:^{
                fail(@"unregistration success block executed incorrectly");
                
            } failure:^(NSError *error) {
                failureBlockExecuted = YES;

            }];
            
            [[theValue(failureBlockExecuted) shouldEventually] beTrue];
        });
    });
});

SPEC_END
