#import "OmniaPushBackEndUnregistrationRequestImpl.h"
#import "OmniaPushFakeNSURLConnectionFactory.h"
#import "OmniaPushNSURLConnectionProvider.h"
#import "OmniaPushNSURLConnectionFactory.h"
#import "OmniaPushErrors.h"
#import "OmniaSpecHelper.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(OmniaPushBackEndUnregistrationRequestImplSpec)

describe(@"OmniaPushBackEndUnregistrationRequestImpl", ^{
    
    __block OmniaPushBackEndUnregistrationRequestImpl *request;
    __block OmniaSpecHelper *helper;
    
    beforeEach(^{
        helper = [[OmniaSpecHelper alloc] init];
        [helper setupConnectionFactory];
        request = [[OmniaPushBackEndUnregistrationRequestImpl alloc] init];
    });
    
    afterEach(^{
        [helper reset];
        helper = nil;
    });
    
    context(@"bad object arguments", ^{
        
        it(@"should require a back-end device ID", ^{
            
            ^{[request startDeviceUnregistration:nil
                                       onSuccess:^(void){}
                                       onFailure:^(NSError*){}];}
            
            should raise_exception([NSException class]);
        });
        
        it(@"should require a success block", ^{
            ^{[request startDeviceUnregistration:helper.backEndDeviceId
                                       onSuccess:nil
                                       onFailure:^(NSError*){}];}
            should raise_exception([NSException class]);
        });
        
        it(@"should require a failure block", ^{
            ^{[request startDeviceUnregistration:helper.backEndDeviceId
                                       onSuccess:^(void){}
                                       onFailure:nil];}
            should raise_exception([NSException class]);
        });
    });
    
    context(@"valid object arguments", ^{
        
        __block NSError *testError;
        __block BOOL wasExpectedResult = NO;
        
        beforeEach(^{
            testError = [NSError errorWithDomain:@"An error of epic proportions" code:0 userInfo:nil];
            wasExpectedResult = NO;
        });
        
        afterEach(^{
            wasExpectedResult should be_truthy;
            testError = nil;
        });
        
        it(@"should handle a failed request", ^{
            [helper.connectionFactory setupForFailureWithError:testError];
            
            [request startDeviceUnregistration:helper.backEndDeviceId
                                     onSuccess:^(void) {
                                         wasExpectedResult = NO;
                                     }
                                     onFailure:^(NSError *error) {
                                         error should equal(testError);
                                         wasExpectedResult = YES;
                                     }];
        });

        it(@"should require an HTTP response", ^{
            __block NSURLResponse *response = [[NSURLResponse alloc] init];
            [helper.connectionFactory setupForSuccessWithResponse:response withDataInChunks:nil];
            
            [request startDeviceUnregistration:helper.backEndDeviceId
                                     onSuccess:^(void) {
                                         wasExpectedResult = NO;
                                     }
                                     onFailure:^(NSError *error) {
                                         error.domain should equal(OmniaPushErrorDomain);
                                         error.code should equal(OmniaPushBackEndUnregistrationNotHTTPResponseError);
                                         wasExpectedResult = YES;
                                     }];
        });

        it(@"should handle an HTTP status error", ^{
            __block NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:500 HTTPVersion:nil headerFields:nil];
            [helper.connectionFactory setupForSuccessWithResponse:response withDataInChunks:nil];
            
            [request startDeviceUnregistration:helper.backEndDeviceId
                                     onSuccess:^(void) {
                                         wasExpectedResult = NO;
                                     }
                                     onFailure:^(NSError *error) {
                                         error.domain should equal(OmniaPushErrorDomain);
                                         error.code should equal(OmniaPushBackEndUnregistrationFailedHTTPStatusCode);
                                         wasExpectedResult = YES;
                                     }];
        });

        it(@"should handle a successful response with empty data", ^{
            __block NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200 HTTPVersion:nil headerFields:nil];
            [helper.connectionFactory setupForSuccessWithResponse:response withDataInChunks:nil];
            
            [request startDeviceUnregistration:helper.backEndDeviceId
                                     onSuccess:^(void) {
                                         wasExpectedResult = YES;
                                     }
                                     onFailure:^(NSError*) {
                                         wasExpectedResult = NO;
                                     }];
        });

        it(@"should handle a successful response with nil data", ^{
            __block NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200 HTTPVersion:nil headerFields:nil];
            [helper.connectionFactory setupForSuccessWithResponse:response withDataInChunks:@[]];
            
            [request startDeviceUnregistration:helper.backEndDeviceId
                                     onSuccess:^(void) {
                                         wasExpectedResult = YES;
                                     }
                                     onFailure:^(NSError*) {
                                         wasExpectedResult = NO;
                                     }];
        });
    });
});

SPEC_END
