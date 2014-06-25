//
//  PMSSPushBackEndRegistrationRequestImplSpec.mm
//  PMSSPushSDK
//
//  Created by Rob Szumlakowski on 2014-02-14.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "Kiwi.h"

#import "NSURLConnection+PMSSPushAsync2Sync.h"
#import "NSURLConnection+PMSSBackEndConnection.h"
#import "PMSSPushURLConnection.h"
#import "PMSSParameters.h"
#import "PMSSPushErrors.h"
#import "PMSSPushSpecHelper.h"

SPEC_BEGIN(PMSSPushBackEndConnectionSpec)

describe(@"PMSSPushBackEndConnection", ^{
    __block PMSSPushSpecHelper *helper;

    beforeEach ( ^{
        helper = [[PMSSPushSpecHelper alloc] init];
        [helper setupParameters];
	});

    afterEach ( ^{
        [helper reset];
        helper = nil;
	});

    context(@"registration bad object arguments", ^{
        it(@"should require an APNS device token", ^{
            [[theBlock( ^{ [PMSSPushURLConnection registerWithParameters:helper.params
                                                            deviceToken:nil
                                                                success: ^(NSURLResponse *response, NSData *data) {}
                                                                failure: ^(NSError *error) {}]; })
              should] raise];
		});

        it(@"should require a registration parameters", ^{
            [[theBlock( ^{ [PMSSPushURLConnection registerWithParameters:nil
                                                            deviceToken:helper.apnsDeviceToken
                                                                success: ^(NSURLResponse *response, NSData *data) {}
                                                                failure: ^(NSError *error) {}]; })
              should] raise];
		});

        it(@"should not require a success block", ^{
            [[theBlock( ^{ [PMSSPushURLConnection registerWithParameters:helper.params
                                                            deviceToken:helper.apnsDeviceToken
                                                                success:nil
                                                                failure: ^(NSError *error) {}]; })
              shouldNot] raise];
		});

        it(@"should not require a failure block", ^{
            [[theBlock( ^{ [PMSSPushURLConnection registerWithParameters:helper.params
                                                            deviceToken:helper.apnsDeviceToken
                                                                success: ^(NSURLResponse *response, NSData *data) {}
                                                                failure:nil]; })
              shouldNot] raise];
		});
	});

    context(@"unregistration bad object arguments", ^{
        it(@"should not require a device ID", ^{
            [[theBlock( ^{ [PMSSPushURLConnection unregisterDeviceID:nil
                                                         parameters:nil
                                                            success: ^(NSURLResponse *response, NSData *data) {}
                                                            failure: ^(NSError *error) {}]; })
              shouldNot] raise];
		});

        it(@"should not require a success block", ^{
            [[theBlock( ^{ [PMSSPushURLConnection unregisterDeviceID:@"Fake Device ID"
                                                         parameters:nil
                                                            success:nil
                                                            failure: ^(NSError *error) {}]; })
              shouldNot] raise];
		});

        it(@"should not require a failure block", ^{
            [[theBlock( ^{ [PMSSPushURLConnection unregisterDeviceID:@"Fake Device ID"
                                                         parameters:nil
                                                            success: ^(NSURLResponse *response, NSData *data) {}
                                                            failure:nil]; })
              shouldNot] raise];
		});
	});

    context(@"valid object arguments", ^{
        __block BOOL wasExpectedResult = NO;

        beforeEach ( ^{
            wasExpectedResult = NO;
		});

        afterEach ( ^{
            [[theValue(wasExpectedResult) should] beTrue];
		});
        
        it(@"should have basic auth headers in the request", ^{
            [NSURLConnection stub:@selector(sendAsynchronousRequest:queue:completionHandler:) withBlock:^id(NSArray *params) {
                NSURLRequest *request = params[0];
                NSString *authValue = request.allHTTPHeaderFields[kBasicAuthorizationKey];
                [[authValue shouldNot] beNil];
                [[authValue should] startWithString:@"Basic "];
                [[authValue should] endWithString:helper.base64AuthString1];
                
                __block NSHTTPURLResponse *newResponse;
                
                if ([request.HTTPMethod isEqualToString:@"POST"]) {
                    newResponse = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200 HTTPVersion:nil headerFields:nil];
                }
                
                CompletionHandler handler = params[2];
                handler(newResponse, nil, nil);
                return nil;
            }];
            
            [PMSSPushURLConnection registerWithParameters:helper.params
                                             deviceToken:helper.apnsDeviceToken
                                                 success: ^(NSURLResponse *response, NSData *data) {
                                                     wasExpectedResult = YES;
                                                 }
             
                                                 failure: ^(NSError *error) {
                                                     wasExpectedResult = NO;
                                                 }];
        });

        it(@"should handle a failed request", ^{
            NSError *error;
            [helper swizzleAsyncRequestWithSelector:@selector(failedRequestRequest:queue:completionHandler:) error:&error];
            [PMSSPushURLConnection registerWithParameters:helper.params
                                             deviceToken:helper.apnsDeviceToken
                                                 success: ^(NSURLResponse *response, NSData *data) {
                                                     wasExpectedResult = NO;
                                                 }
                                                 failure: ^(NSError *error) {
                                                     [[error.domain should] equal:NSURLErrorDomain];
                                                     wasExpectedResult = YES;
                                                 }];
		});
	});
});

SPEC_END
