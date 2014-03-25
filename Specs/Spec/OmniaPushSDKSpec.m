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
#import "OmniaPushRegistrationParameters.h"
#import "OmniaPushBackEndRegistrationResponseDataTest.h"
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
            [[theBlock(^{[OmniaPushSDK registerWithParameters:nil
                                                      success:^{
                                                          blockExecuted = YES;
                                                      }
                                                      failure:^(NSError *error) {
                                                          blockExecuted = YES;
                                                      }];})
              should] raise];
            [[theValue(blockExecuted) should] beFalse];
            
            [[theBlock(^{[OmniaPushSDK registerWithParameters:nil];})
              should] raise];
        });
    });
    
    typedef void (^Handler)(NSURLResponse* response, NSData* data, NSError* connectionError);

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
                [helper setupDefaultSavedParameters];
                [OmniaPushPersistentStorage performSelector:selectors[i] withObject:@"DIFFERENT_VALUE"];
                
                [OmniaPushSDK registerWithParameters:helper.params
                                             success:^ {
                                                 successCount++;
                                             }
                                             failure:^(NSError *error) {
                                                 fail(@"registration failure block executed");
                                             }];
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
            [[[OmniaPushPersistentStorage APNSDeviceToken] should] beNil];
            expectedResult = NO;
            testError = nil;
        });
        
        it(@"should handle registration failures from APNS", ^{
            [[helper.application shouldEventually] receive:@selector(registerForRemoteNotificationTypes:)];
            [[(id)helper.applicationDelegate shouldEventually] receive:@selector(application:didFailToRegisterForRemoteNotificationsWithError:)];

            [OmniaPushSDK registerWithParameters:helper.params
                                         success:nil
                                         failure:^(NSError *error) {
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
                                               successBlock:^{
                                                   wasExpectedResult = NO;
                                               }
                                               failureBlock:^(NSError *error) {
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
                                               successBlock:^{
                                                   wasExpectedResult = NO;
                                               }
                                               failureBlock:^(NSError *error) {
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
                                               successBlock:^{
                                                   wasExpectedResult = NO;
                                               }
                                               failureBlock:^(NSError *error) {
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
                                               successBlock:^{
                                                   wasExpectedResult = NO;
                                               }
                                               failureBlock:^(NSError *error) {
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
            
            [OmniaPushSDK sendRegisterRequestWithParameters:helper.params
                                                   devToken:helper.apnsDeviceToken
                                               successBlock:^{
                                                   wasExpectedResult = NO;
                                               }
                                               failureBlock:^(NSError *error) {
                                                   wasExpectedResult = YES;
                                                   [[error.domain should] equal:OmniaPushErrorDomain];
                                                   [[theValue(error.code) should] equal:theValue(OmniaPushBackEndRegistrationResponseDataNoDeviceUuid)];
                                               }];
        });
        
    });
});

SPEC_END
