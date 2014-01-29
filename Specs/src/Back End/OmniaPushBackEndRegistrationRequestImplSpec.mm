#import "OmniaPushBackEndRegistrationRequestImpl.h"
#import "OmniaPushBackEndRegistrationResponseData.h"
#import "OmniaPushFakeNSURLConnectionFactory.h"
#import "OmniaPushNSURLConnectionProvider.h"
#import "OmniaPushNSURLConnectionFactory.h"
#import "OmniaPushErrors.h"
#import "OmniaSpecHelper.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(OmniaPushBackEndRegistrationRequestImplSpec)

describe(@"OmniaPushBackEndRegistrationRequestImpl", ^{
    
    __block OmniaPushBackEndRegistrationRequestImpl *request;
    __block OmniaSpecHelper *helper;

    beforeEach(^{
        helper = [[OmniaSpecHelper alloc] init];
        [helper setupParametersWithNotificationTypes:TEST_NOTIFICATION_TYPES];
        [helper setupConnectionFactory];
        request = [[OmniaPushBackEndRegistrationRequestImpl alloc] init];
    });
    
    afterEach(^{
        [helper reset];
        helper = nil;
    });
    
    context(@"bad object arguments", ^{
        
        it(@"should require an APNS device token", ^{
            ^{[request startDeviceRegistration:nil
                                    parameters:helper.params
                                     onSuccess:^(OmniaPushBackEndRegistrationResponseData*){}
                                     onFailure:^(NSError*){}];}
            should raise_exception([NSException class]);
        });

        it(@"should require a registration parameters", ^{
            ^{[request startDeviceRegistration:helper.apnsDeviceToken
                                    parameters:nil
                                     onSuccess:^(OmniaPushBackEndRegistrationResponseData*){}
                                     onFailure:^(NSError*){}];}
            should raise_exception([NSException class]);
        });
        
        it(@"should require a success block", ^{
            ^{[request startDeviceRegistration:helper.apnsDeviceToken
                                    parameters:helper.params
                                     onSuccess:nil
                                     onFailure:^(NSError*){}];}
            should raise_exception([NSException class]);
        });
        
        it(@"should require a failure block", ^{
            ^{[request startDeviceRegistration:helper.apnsDeviceToken
                                    parameters:helper.params
                                     onSuccess:^(OmniaPushBackEndRegistrationResponseData*){}
                                     onFailure:nil];}
            should raise_exception([NSException class]);
        });
    });
    
    context(@"valid object arguments", ^{
        
        __block NSError *testError;
        __block BOOL wasExpectedResult;

        beforeEach(^{
            testError = [NSError errorWithDomain:@"Crazy, yet amusing, error" code:0 userInfo:nil];
            wasExpectedResult = NO;
        });
        
        afterEach(^{
            testError = nil;
        });
        
        it(@"should handle a failed request", ^{
            [helper.connectionFactory setupForFailureWithError:testError];
            
            [request startDeviceRegistration:helper.apnsDeviceToken
                                  parameters:helper.params
                                   onSuccess:^(OmniaPushBackEndRegistrationResponseData*) {
                                       wasExpectedResult = NO;
                                   }
                                   onFailure:^(NSError *error) {
                                       error should equal(testError);
                                       wasExpectedResult = YES;
                                   }];
            
            wasExpectedResult should be_truthy;
        });
        
        it(@"should require an HTTP response", ^{
            __block NSURLResponse *response = [[NSURLResponse alloc] init];
            [helper.connectionFactory setupForSuccessWithResponse:response withDataInChunks:nil];
            
            [request startDeviceRegistration:helper.apnsDeviceToken
                                  parameters:helper.params
                                   onSuccess:^(OmniaPushBackEndRegistrationResponseData*) {
                                       wasExpectedResult = NO;
                                   }
                                   onFailure:^(NSError *error) {
                                       error.domain should equal(OmniaPushErrorDomain);
                                       error.code should equal(OmniaPushBackEndRegistrationNotHTTPResponseError);
                                       wasExpectedResult = YES;
                                   }];
            
            wasExpectedResult should be_truthy;
        });

        it(@"should handle an HTTP status error", ^{
            __block NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:400 HTTPVersion:nil headerFields:nil];
            [helper.connectionFactory setupForSuccessWithResponse:response withDataInChunks:nil];
            
            [request startDeviceRegistration:helper.apnsDeviceToken
                                  parameters:helper.params
                                   onSuccess:^(OmniaPushBackEndRegistrationResponseData*) {
                                       wasExpectedResult = NO;
                                   }
                                   onFailure:^(NSError *error) {
                                       error.domain should equal(OmniaPushErrorDomain);
                                       error.code should equal(OmniaPushBackEndRegistrationFailedHTTPStatusCode);
                                       wasExpectedResult = YES;
                                   }];
            
            wasExpectedResult should be_truthy;
        });
        
        it(@"should handle a succesful response with empty data", ^{
            __block NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200 HTTPVersion:nil headerFields:nil];
            [helper.connectionFactory setupForSuccessWithResponse:response withDataInChunks:nil];
            
            [request startDeviceRegistration:helper.apnsDeviceToken
                                  parameters:helper.params
                                   onSuccess:^(OmniaPushBackEndRegistrationResponseData*) {
                                       wasExpectedResult = NO;
                                   }
                                   onFailure:^(NSError *error) {
                                       error.domain should equal(OmniaPushErrorDomain);
                                       error.code should equal(OmniaPushBackEndRegistrationEmptyResponseData);
                                       wasExpectedResult = YES;
                                   }];
            
            wasExpectedResult should be_truthy;
        });
        
        it(@"should handle a succesful response with nil data", ^{
            __block NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200 HTTPVersion:nil headerFields:nil];
            [helper.connectionFactory setupForSuccessWithResponse:response withDataInChunks:@[]];
            
            [request startDeviceRegistration:helper.apnsDeviceToken
                                  parameters:helper.params
                                   onSuccess:^(OmniaPushBackEndRegistrationResponseData*) {
                                       wasExpectedResult = NO;
                                   }
                                   onFailure:^(NSError *error) {
                                       error.domain should equal(OmniaPushErrorDomain);
                                       error.code should equal(OmniaPushBackEndRegistrationEmptyResponseData);
                                       wasExpectedResult = YES;
                                   }];
            
            wasExpectedResult should be_truthy;
        });
        
        it(@"should handle a succesful response with zero-length", ^{
            __block NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200 HTTPVersion:nil headerFields:nil];
            [helper.connectionFactory setupForSuccessWithResponse:response withDataInChunks:@[@""]];
            
            [request startDeviceRegistration:helper.apnsDeviceToken
                                  parameters:helper.params
                                   onSuccess:^(OmniaPushBackEndRegistrationResponseData*) {
                                       wasExpectedResult = NO;
                                   }
                                   onFailure:^(NSError *error) {
                                       error.domain should equal(OmniaPushErrorDomain);
                                       error.code should equal(OmniaPushBackEndRegistrationEmptyResponseData);
                                       wasExpectedResult = YES;
                                   }];
            
            wasExpectedResult should be_truthy;
        });
        
        it(@"should handle a succesful response that contains unparseable text", ^{
            __block NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200 HTTPVersion:nil headerFields:nil];
            [helper.connectionFactory setupForSuccessWithResponse:response withDataInChunks:@[@"I AM NOT JSON"]];
            
            [request startDeviceRegistration:helper.apnsDeviceToken
                                  parameters:helper.params
                                   onSuccess:^(OmniaPushBackEndRegistrationResponseData*) {
                                       wasExpectedResult = NO;
                                   }
                                   onFailure:^(NSError *error) {
                                       error should_not be_nil;
                                       wasExpectedResult = YES;
                                   }];
            
            wasExpectedResult should be_truthy;
        });
    });
    
});

SPEC_END
