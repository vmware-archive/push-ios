//
//  OmniaPushBackEndRegistrationRequestImplSpec.mm
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-02-14.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "Kiwi.h"

#import "NSURLConnection+OmniaAsync2Sync.h"
#import "OmniaPushBackEndConnection.h"
#import "OmniaFakeOperationQueue.h"
#import "OmniaPushErrors.h"
#import "OmniaSpecHelper.h"

SPEC_BEGIN(OmniaPushBackEndConnectionSpec)

describe(@"OmniaPushBackEndConnection", ^{
    
    __block OmniaSpecHelper *helper;

    beforeEach(^{
        helper = [[OmniaSpecHelper alloc] init];
        [helper setupParametersWithNotificationTypes:TEST_NOTIFICATION_TYPES];
        [helper setupQueues];
    });
    
    afterEach(^{
        [helper reset];
        helper = nil;
    });
    
    context(@"bad object arguments", ^{
        
        it(@"should require an APNS device token", ^{
            [[^{[OmniaPushBackEndConnection sendRegistrationRequestOnQueue:helper.workerQueue
                                                          withParameters:helper.params
                                                                devToken:nil
                                                                 success:^(NSURLResponse *response, NSData *data) {}
                                                                 failure:^(NSURLResponse *response, NSError *error) {}];}
              should] raise];
        });
        
        it(@"should require a registration parameters", ^{
            [[^{[OmniaPushBackEndConnection sendRegistrationRequestOnQueue:helper.workerQueue
                                                           withParameters:nil
                                                                 devToken:helper.apnsDeviceToken
                                                                  success:^(NSURLResponse *response, NSData *data) {}
                                                                  failure:^(NSURLResponse *response, NSError *error) {}];}
             should] raise];
        });
        
        it(@"should require a success block", ^{
            [[^{[OmniaPushBackEndConnection sendRegistrationRequestOnQueue:helper.workerQueue
                                                          withParameters:helper.params
                                                                devToken:helper.apnsDeviceToken
                                                                 success:nil
                                                                 failure:^(NSURLResponse *response, NSError *error) {}];}
            should] raise];
        });
        
        it(@"should require a failure block", ^{
            [[^{[OmniaPushBackEndConnection sendRegistrationRequestOnQueue:helper.workerQueue
                                                            withParameters:helper.params
                                                                  devToken:helper.apnsDeviceToken
                                                                   success:^(NSURLResponse *response, NSData *data) {}
                                                                   failure:nil];}
              should] raise];
        });
    });
    
    context(@"valid object arguments", ^{
        
        __block BOOL wasExpectedResult = NO;

        beforeEach(^{
            wasExpectedResult = NO;
        });
        
        afterEach(^{
            [[theValue(wasExpectedResult) should] beTrue];
        });
        
        it(@"should handle a failed request", ^{
            NSError *error;
            [helper swizzleAsyncRequestWithSelector:@selector(failedRequestRequest:queue:completionHandler:) error:&error];
            [OmniaPushBackEndConnection sendRegistrationRequestOnQueue:helper.workerQueue
                                                        withParameters:helper.params
                                                              devToken:helper.apnsDeviceToken
                                                               success:^(NSURLResponse *response, NSData *data) {
                                                                   wasExpectedResult = NO;
                                                               }
                                                               failure:^(NSURLResponse *response, NSError *error) {
                                                                   [[error.domain should] equal:NSURLErrorDomain];
                                                                   wasExpectedResult = YES;
                                                               }];
        });

        it(@"should handle an HTTP status error", ^{
            NSError *error;
            [helper swizzleAsyncRequestWithSelector:@selector(HTTPErrorResponseRequest:queue:completionHandler:) error:&error];

            [OmniaPushBackEndConnection sendRegistrationRequestOnQueue:helper.workerQueue
                                                        withParameters:helper.params
                                                              devToken:helper.apnsDeviceToken
                                                               success:^(NSURLResponse *response, NSData *data) {
                                                                   wasExpectedResult = NO;
                                                                }
                                                               failure:^(NSURLResponse *response, NSError *error) {
                                                                   [[error.domain should] equal:OmniaPushErrorDomain];
                                                                   [[theValue(error.code) should] equal:theValue(OmniaPushBackEndRegistrationFailedHTTPStatusCode)];
                                                                   wasExpectedResult = YES;
                                                               }];
        });
        
        it(@"should handle a successful response with empty data", ^{
            NSError *error;
            [helper swizzleAsyncRequestWithSelector:@selector(emptyDataResponseRequest:queue:completionHandler:) error:&error];
            
            [OmniaPushBackEndConnection sendRegistrationRequestOnQueue:helper.workerQueue
                                                        withParameters:helper.params
                                                              devToken:helper.apnsDeviceToken
                                                               success:^(NSURLResponse *response, NSData *data) {
                                                                   wasExpectedResult = NO;
                                                               }
                                                               failure:^(NSURLResponse *response, NSError *error) {
                                                                   [[error.domain should] equal:OmniaPushErrorDomain];
                                                                   [[theValue(error.code) should] equal:theValue(OmniaPushBackEndRegistrationEmptyResponseData)];
                                                                   wasExpectedResult = YES;
                                                               }];
            
        });
        
        it(@"should handle a successful response with nil data", ^{
            NSError *error;
            [helper swizzleAsyncRequestWithSelector:@selector(nilDataResponseRequest:queue:completionHandler:) error:&error];
            
            [OmniaPushBackEndConnection sendRegistrationRequestOnQueue:helper.workerQueue
                                                        withParameters:helper.params
                                                              devToken:helper.apnsDeviceToken
                                                               success:^(NSURLResponse *response, NSData *data) {
                                                                   wasExpectedResult = NO;
                                                               }
                                                               failure:^(NSURLResponse *response, NSError *error) {
                                                                   [[error.domain should] equal:OmniaPushErrorDomain];
                                                                   [[theValue(error.code) should] equal:theValue(OmniaPushBackEndRegistrationEmptyResponseData)];
                                                                   wasExpectedResult = YES;
                                                               }];
        });
        
        it(@"should handle a successful response with zero-length", ^{
            NSError *error;
            [helper swizzleAsyncRequestWithSelector:@selector(zeroLengthDataResponseRequest:queue:completionHandler:) error:&error];
            
            [OmniaPushBackEndConnection sendRegistrationRequestOnQueue:helper.workerQueue
                                                        withParameters:helper.params
                                                              devToken:helper.apnsDeviceToken
                                                               success:^(NSURLResponse *response, NSData *data) {
                                                                   wasExpectedResult = NO;
                                                               }
                                                               failure:^(NSURLResponse *response, NSError *error) {
                                                                   [[error.domain should] equal:OmniaPushErrorDomain];
                                                                   [[theValue(error.code) should] equal:theValue(OmniaPushBackEndRegistrationEmptyResponseData)];
                                                                   wasExpectedResult = YES;
                                                               }];
        });
        
        it(@"should handle a successful response that contains unparseable text", ^{
            NSError *error;
            [helper swizzleAsyncRequestWithSelector:@selector(unparseableDataResponseRequest:queue:completionHandler:) error:&error];
            
            [OmniaPushBackEndConnection sendRegistrationRequestOnQueue:helper.workerQueue
                                                        withParameters:helper.params
                                                              devToken:helper.apnsDeviceToken
                                                               success:^(NSURLResponse *response, NSData *data) {
                                                                   wasExpectedResult = NO;
                                                               }
                                                               failure:^(NSURLResponse *response, NSError *error) {
                                                                   [[error shouldNot] beNil];
                                                                   wasExpectedResult = YES;
                                                               }];
        });
        
        it(@"should require a device_uuid in the server response", ^{
            NSError *error;
            [helper swizzleAsyncRequestWithSelector:@selector(missingUUIDResponseRequest:queue:completionHandler:) error:&error];
            
            [OmniaPushBackEndConnection sendRegistrationRequestOnQueue:helper.workerQueue
                                                        withParameters:helper.params
                                                              devToken:helper.apnsDeviceToken
                                                               success:^(NSURLResponse *response, NSData *data) {
                                                                   wasExpectedResult = NO;
                                                               }
                                                               failure:^(NSURLResponse *response, NSError *error) {
                                                                   wasExpectedResult = YES;
                                                                   [[error.domain should] equal:OmniaPushErrorDomain];
                                                                   [[theValue(error.code) should] equal:theValue(OmniaPushBackEndRegistrationResponseDataNoDeviceUuid)];
                                                               }];
        });
            
    });
    
});

SPEC_END
