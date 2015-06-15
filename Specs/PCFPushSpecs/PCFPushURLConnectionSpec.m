//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "Kiwi.h"

#import "NSURLConnection+PCFBackEndConnection.h"
#import "PCFPushURLConnection.h"
#import "PCFPushParameters.h"
#import "PCFPushErrors.h"
#import "PCFPushSpecsHelper.h"
#import "PCFPushClient.h"

SPEC_BEGIN(PCFPushURLConnectionSpec)

describe(@"PCFPushBackEndConnection", ^{
    __block PCFPushSpecsHelper *helper;

    beforeEach ( ^{
        [PCFPushClient resetSharedClient];
        helper = [[PCFPushSpecsHelper alloc] init];
        [helper setupParameters];
	});

    afterEach ( ^{
        [helper reset];
        helper = nil;
	});

    context(@"registration bad object arguments", ^{
        it(@"should require an APNS device token", ^{
            [[theBlock( ^{ [PCFPushURLConnection registerWithParameters:helper.params
                                                            deviceToken:nil
                                                                success:^(NSURLResponse *response, NSData *data) {
                                                                }
                                                                failure:^(NSError *error) {
                                                                }]; })
              should] raise];
		});

        it(@"should require a registration parameters", ^{
            [[theBlock( ^{ [PCFPushURLConnection registerWithParameters:nil
                                                            deviceToken:helper.apnsDeviceToken
                                                                success:^(NSURLResponse *response, NSData *data) {
                                                                }
                                                                failure:^(NSError *error) {
                                                                }]; })
              should] raise];
		});

        it(@"should not require a success block", ^{
            [[theBlock( ^{ [PCFPushURLConnection registerWithParameters:helper.params
                                                            deviceToken:helper.apnsDeviceToken
                                                                success:nil
                                                                failure:^(NSError *error) {
                                                                }]; })
              shouldNot] raise];
		});

        it(@"should not require a failure block", ^{
            [[theBlock( ^{ [PCFPushURLConnection registerWithParameters:helper.params
                                                            deviceToken:helper.apnsDeviceToken
                                                                success:^(NSURLResponse *response, NSData *data) {
                                                                }
                                                                failure:nil]; })
              shouldNot] raise];
		});
	});

    context(@"unregistration bad object arguments", ^{
        it(@"should not require a device ID", ^{
            [[theBlock( ^{ [PCFPushURLConnection unregisterDeviceID:nil
                                                         parameters:nil
                                                            success:^(NSURLResponse *response, NSData *data) {
                                                            }
                                                            failure:^(NSError *error) {
                                                            }]; })
              shouldNot] raise];
		});

        it(@"should not require a success block", ^{
            [[theBlock( ^{ [PCFPushURLConnection unregisterDeviceID:@"Fake Device ID"
                                                         parameters:nil
                                                            success:nil
                                                            failure:^(NSError *error) {
                                                            }]; })
              shouldNot] raise];
		});

        it(@"should not require a failure block", ^{
            [[theBlock( ^{ [PCFPushURLConnection unregisterDeviceID:@"Fake Device ID"
                                                         parameters:nil
                                                            success:^(NSURLResponse *response, NSData *data) {
                                                            }
                                                            failure:nil]; })
              shouldNot] raise];
		});
	});

    context(@"arguments for geofence updates", ^{
        it(@"should require a parameters object", ^{
            [[theBlock( ^{
                [PCFPushURLConnection geofenceRequestWithParameters:nil timestamp:77777L deviceUuid:@"DEVICE_UUID" success:^(NSURLResponse *response, NSData *data) {} failure:^(NSError *error) {}];
            }) should] raiseWithName:NSInvalidArgumentException];
        });

        it(@"should not require a success block", ^{
            [[theBlock( ^{
                [PCFPushURLConnection geofenceRequestWithParameters:helper.params timestamp:77777L deviceUuid:@"DEVICE_UUID" success:nil failure:^(NSError *error) {}];
            }) shouldNot] raise];
        });

        it(@"should not require a failure block", ^{
            [[theBlock( ^{
                [PCFPushURLConnection geofenceRequestWithParameters:helper.params timestamp:77777L deviceUuid:@"DEVICE_UUID" success:^(NSURLResponse *response, NSData *data) {} failure:nil];
            }) shouldNot] raise];
        });

        it(@"should require a device UUID", ^{
            [[theBlock( ^{
                [PCFPushURLConnection geofenceRequestWithParameters:helper.params timestamp:77777L deviceUuid:nil success:^(NSURLResponse *response, NSData *data) {} failure:nil];
            }) should] raiseWithName:NSInvalidArgumentException];
        });
    });

    context(@"geofence updates", ^{
            __block BOOL wasExpectedResult = NO;

            beforeEach ( ^{
                wasExpectedResult = NO;
            });

            afterEach ( ^{
                [[theValue(wasExpectedResult) should] beTrue];
            });

            it(@"should handle a success request", ^{
                [NSURLConnection stub:@selector(pcfPushSendAsynchronousRequestWrapper:queue:completionHandler:) withBlock:^id(NSArray *params) {
                    NSURLRequest *request = params[0];
                    //TODO: Verify basic auth once we have a real server

                    [[request.HTTPMethod should] equal:@"GET"];
                    [[request.URL.absoluteString should] endWithString:@"?timestamp=77777&device_uuid=DEVICE_UUID&platform=ios"];

                    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200 HTTPVersion:nil headerFields:nil];

                    CompletionHandler handler = params[2];
                    handler(response, nil, nil);
                    return nil;
                }];
                [PCFPushURLConnection geofenceRequestWithParameters:helper.params timestamp:77777L deviceUuid:@"DEVICE_UUID" success:^(NSURLResponse *response, NSData *data) {
                    wasExpectedResult = YES;
                }                                           failure:^(NSError *error) {
                    wasExpectedResult = NO;
                }];
            });

            it(@"should handle a failure request", ^{
                [NSURLConnection stub:@selector(pcfPushSendAsynchronousRequestWrapper:queue:completionHandler:) withBlock:^id(NSArray *params) {
                    NSURLRequest *request = params[0];
                    //TODO: Verify basic auth once we have a real server

                    [[request.HTTPMethod should] equal:@"GET"];
                    [[request.URL.absoluteString should] endWithString:@"?timestamp=77777&device_uuid=DEVICE_UUID&platform=ios"];

                    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:400 HTTPVersion:nil headerFields:nil];

                    CompletionHandler handler = params[2];
                    handler(response, nil, nil);
                    return nil;
                }];

                [PCFPushURLConnection geofenceRequestWithParameters:helper.params timestamp:77777L deviceUuid:@"DEVICE_UUID" success:^(NSURLResponse *response, NSData *data) {
                    wasExpectedResult = NO;
                }                                           failure:^(NSError *error) {
                    wasExpectedResult = YES;
                }];
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
            [NSURLConnection stub:@selector(pcfPushSendAsynchronousRequestWrapper:queue:completionHandler:) withBlock:^id(NSArray *params) {
                NSURLRequest *request = params[0];
                NSString *authValue = request.allHTTPHeaderFields[kPCFPushBasicAuthorizationKey];
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

            [PCFPushURLConnection registerWithParameters:helper.params
                                             deviceToken:helper.apnsDeviceToken
                                                 success:^(NSURLResponse *response, NSData *data) {
                                                     wasExpectedResult = YES;
                                                 }

                                                 failure:^(NSError *error) {
                                                     wasExpectedResult = NO;
                                                 }];
        });

        it(@"should return a sensible error code if the authentication fails", ^{
            [NSURLConnection stub:@selector(pcfPushSendAsynchronousRequestWrapper:queue:completionHandler:) withBlock:^id(NSArray *params) {
                NSError *authError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorUserCancelledAuthentication userInfo:nil];
                CompletionHandler handler = params[2];
                handler(nil, nil, authError);
                return nil;
            }];

            [PCFPushURLConnection registerWithParameters:helper.params
                                             deviceToken:helper.apnsDeviceToken
                                                 success:^(NSURLResponse *response, NSData *data) {
                                                     wasExpectedResult = NO;
                                                 }

                                                 failure:^(NSError *error) {
                                                     wasExpectedResult = YES;
                                                     [[error.domain should] equal:PCFPushErrorDomain];
                                                     [[theValue(error.code) should] equal:theValue(PCFPushBackEndRegistrationAuthenticationError)];
                                                 }];
        });

        it(@"should handle a failed request", ^{
            [NSURLConnection stub:@selector(pcfPushSendAsynchronousRequestWrapper:queue:completionHandler:) withBlock:^id(NSArray *params) {
                NSDictionary *userInfo = @{
                        @"NSLocalizedDescription" : @"bad URL",
                        @"NSUnderlyingError" : [NSError errorWithDomain:(NSString *) kCFErrorDomainCFNetwork code:1000 userInfo:@{@"NSLocalizedDescription" : @"bad URL"}],
                };
                NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:1000 userInfo:userInfo];
                CompletionHandler handler = params[2];
                handler(nil, nil, error);
                return nil;
            }];

            [PCFPushURLConnection registerWithParameters:helper.params
                                             deviceToken:helper.apnsDeviceToken
                                                 success:^(NSURLResponse *response, NSData *data) {
                                                     wasExpectedResult = NO;
                                                 }
                                                 failure:^(NSError *error) {
                                                     [[error.domain should] equal:NSURLErrorDomain];
                                                     wasExpectedResult = YES;
                                                 }];
		});
	});
});

SPEC_END
