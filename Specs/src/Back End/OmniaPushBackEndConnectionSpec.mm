//
//  OmniaPushBackEndRegistrationRequestImplSpec.mm
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-02-14.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "OmniaPushBackEndConnection.h"
#import "OmniaFakeOperationQueue.h"
#import "OmniaPushErrors.h"
#import "OmniaSpecHelper.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(OmniaPushBackEndConnectionSpec)

describe(@"OmniaPushBackEndConnection", ^{
    
    __block OmniaSpecHelper *helper;

    beforeEach(^{
        helper = [[OmniaSpecHelper alloc] init];
        [helper setupParametersWithNotificationTypes:TEST_NOTIFICATION_TYPES];
    });
    
    afterEach(^{
        [helper reset];
        helper = nil;
    });
    
    context(@"bad object arguments", ^{
        
        it(@"should require an APNS device token", ^{
            ^{[OmniaPushBackEndConnection sendRegistrationRequestOnQueue:helper.workerQueue
                                                          withParameters:helper.params
                                                                devToken:nil
                                                                 success:^(NSURLResponse *response, NSData *data) {}
                                                                 failure:^(NSURLResponse *response, NSError *error) {}];}
            should raise_exception([NSException class]);
        });

        it(@"should require a registration parameters", ^{
            ^{[OmniaPushBackEndConnection sendRegistrationRequestOnQueue:helper.workerQueue
                                                          withParameters:nil
                                                                devToken:helper.apnsDeviceToken
                                                                 success:^(NSURLResponse *response, NSData *data) {}
                                                                 failure:^(NSURLResponse *response, NSError *error) {}];}
            should raise_exception([NSException class]);
        });
        
        it(@"should require a success block", ^{
            ^{[OmniaPushBackEndConnection sendRegistrationRequestOnQueue:helper.workerQueue
                                                          withParameters:helper.params
                                                                devToken:helper.apnsDeviceToken
                                                                 success:nil
                                                                 failure:^(NSURLResponse *response, NSError *error) {}];}
            should raise_exception([NSException class]);
        });
        
        it(@"should require a failure block", ^{
            ^{[OmniaPushBackEndConnection sendRegistrationRequestOnQueue:helper.workerQueue
                                                          withParameters:helper.params
                                                                devToken:helper.apnsDeviceToken
                                                                 success:^(NSURLResponse *response, NSData *data) {}
                                                                 failure:nil];}
            should raise_exception([NSException class]);
        });
    });
    
    context(@"valid object arguments", ^{
        
        __block NSError *testError;
        __block BOOL wasExpectedResult = NO;

        beforeEach(^{
            testError = [NSError errorWithDomain:@"Crazy, yet amusing, error" code:0 userInfo:nil];
            wasExpectedResult = NO;
        });
        
        afterEach(^{
            wasExpectedResult should be_truthy;
            testError = nil;
        });
        
        it(@"should handle a failed request", ^{
            [OmniaPushBackEndConnection sendRegistrationRequestOnQueue:helper.workerQueue
                                                        withParameters:helper.params
                                                              devToken:helper.apnsDeviceToken
                                                               success:^(NSURLResponse *response, NSData *data) {
                                                                   wasExpectedResult = NO;
                                                               }
                                                               failure:^(NSURLResponse *response, NSError *error) {
                                                                   error should equal(testError);
                                                                   wasExpectedResult = YES;
                                                               }];
        });
        
        it(@"should require an HTTP response", ^{
            [OmniaPushBackEndConnection sendRegistrationRequestOnQueue:helper.workerQueue
                                                        withParameters:helper.params
                                                              devToken:helper.apnsDeviceToken
                                                               success:^(NSURLResponse *response, NSData *data) {
                                                                   wasExpectedResult = NO;
                                                               }
                                                               failure:^(NSURLResponse *response, NSError *error) {
                                                                   error.domain should equal(OmniaPushErrorDomain);
                                                                   error.code should equal(OmniaPushBackEndRegistrationNotHTTPResponseError);
                                                                   wasExpectedResult = YES;
                                                               }];
        });

        it(@"should handle an HTTP status error", ^{
            [OmniaPushBackEndConnection sendRegistrationRequestOnQueue:helper.workerQueue
                                                        withParameters:helper.params
                                                              devToken:helper.apnsDeviceToken
                                                               success:^(NSURLResponse *response, NSData *data) {
                                                                   wasExpectedResult = NO;
                                                               }
                                                               failure:^(NSURLResponse *response, NSError *error) {
                                                                   error.domain should equal(OmniaPushErrorDomain);
                                                                   error.code should equal(OmniaPushBackEndRegistrationFailedHTTPStatusCode);
                                                                   wasExpectedResult = YES;
                                                               }];
        });
        
        it(@"should handle a successful response with empty data", ^{
            [OmniaPushBackEndConnection sendRegistrationRequestOnQueue:helper.workerQueue
                                                        withParameters:helper.params
                                                              devToken:helper.apnsDeviceToken
                                                               success:^(NSURLResponse *response, NSData *data) {
                                                                   wasExpectedResult = NO;
                                                               }
                                                               failure:^(NSURLResponse *response, NSError *error) {
                                                                   error.domain should equal(OmniaPushErrorDomain);
                                                                   error.code should equal(OmniaPushBackEndRegistrationEmptyResponseData);
                                                                   wasExpectedResult = YES;
                                                               }];
            
        });
        
        it(@"should handle a successful response with nil data", ^{
            [OmniaPushBackEndConnection sendRegistrationRequestOnQueue:helper.workerQueue
                                                        withParameters:helper.params
                                                              devToken:helper.apnsDeviceToken
                                                               success:^(NSURLResponse *response, NSData *data) {
                                                                   wasExpectedResult = NO;
                                                               }
                                                               failure:^(NSURLResponse *response, NSError *error) {
                                                                   error.domain should equal(OmniaPushErrorDomain);
                                                                   error.code should equal(OmniaPushBackEndRegistrationEmptyResponseData);
                                                                   wasExpectedResult = YES;
                                                               }];
        });
        
        it(@"should handle a successful response with zero-length", ^{
            [OmniaPushBackEndConnection sendRegistrationRequestOnQueue:helper.workerQueue
                                                        withParameters:helper.params
                                                              devToken:helper.apnsDeviceToken
                                                               success:^(NSURLResponse *response, NSData *data) {
                                                                   wasExpectedResult = NO;
                                                               }
                                                               failure:^(NSURLResponse *response, NSError *error) {
                                                                   error.domain should equal(OmniaPushErrorDomain);
                                                                   error.code should equal(OmniaPushBackEndRegistrationEmptyResponseData);
                                                                   wasExpectedResult = YES;
                                                               }];
        });
        
        it(@"should handle a successful response that contains unparseable text (1)", ^{
            [OmniaPushBackEndConnection sendRegistrationRequestOnQueue:helper.workerQueue
                                                        withParameters:helper.params
                                                              devToken:helper.apnsDeviceToken
                                                               success:^(NSURLResponse *response, NSData *data) {
                                                                   wasExpectedResult = NO;
                                                               }
                                                               failure:^(NSURLResponse *response, NSError *error) {
                                                                   error should_not be_nil;
                                                                   wasExpectedResult = YES;
                                                               }];
        });
        
        it(@"should handle a successful response that contains unparseable text (2)", ^{
//            __block NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200 HTTPVersion:nil headerFields:nil];
//            [helper.connectionFactory setupForSuccessWithResponse:response withDataInChunks:@[[@"I AM NOT JSON" dataUsingEncoding:NSUTF8StringEncoding]]];
            
            [OmniaPushBackEndConnection sendRegistrationRequestOnQueue:helper.workerQueue
                                                        withParameters:helper.params
                                                              devToken:helper.apnsDeviceToken
                                                               success:^(NSURLResponse *response, NSData *data) {
                                                                   wasExpectedResult = NO;
                                                               }
                                                               failure:^(NSURLResponse *response, NSError *error) {
                                                                   error should_not be_nil;
                                                                   wasExpectedResult = YES;
                                                               }];
        });
        
        it(@"should require a device_uuid in the server response", ^{
//            __block NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200 HTTPVersion:nil headerFields:nil];
//            [helper.connectionFactory setupForSuccessWithResponse:response withDataInChunks:@[@"{\"os\":\"AmigaOS\"}"]];
            
            [OmniaPushBackEndConnection sendRegistrationRequestOnQueue:helper.workerQueue
                                                        withParameters:helper.params
                                                              devToken:helper.apnsDeviceToken
                                                               success:^(NSURLResponse *response, NSData *data) {
                                                                   wasExpectedResult = NO;
                                                               }
                                                               failure:^(NSURLResponse *response, NSError *error) {
                                                                   wasExpectedResult = YES;
                                                                   error.domain should equal(OmniaPushErrorDomain);
                                                                   error.code should equal(OmniaPushBackEndRegistrationResponseDataNoDeviceUuid);
                                                               }];
        });
            
    });
    
});

SPEC_END
