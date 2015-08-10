//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "Kiwi.h"
#import "PCFPushErrors.h"
#import "PCFPushClient.h"
#import "PCFPushParameters.h"
#import "PCFPushSpecsHelper.h"
#import "PCFPushURLConnection.h"
#import "PCFPushPersistentStorage.h"
#import "NSURLConnection+PCFBackEndConnection.h"

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

                [PCFPushPersistentStorage setRequestHeaders:@{ @"RABBIT SEASON":@"DUCK SEASON", @"Basic":@"Should be ignored" } ];

                [NSURLConnection stub:@selector(pcfPushSendAsynchronousRequestWrapper:queue:completionHandler:) withBlock:^id(NSArray *params) {
                    NSURLRequest *request = params[0];

                    [[request.allHTTPHeaderFields[@"Authorization"] should] equal:[@"Basic  " stringByAppendingString:helper.base64AuthString1]];
                    [[request.allHTTPHeaderFields[@"RABBIT SEASON"] should] equal:@"DUCK SEASON"];

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

                    [[request.allHTTPHeaderFields[@"Authorization"] should] equal:[@"Basic  " stringByAppendingString:helper.base64AuthString1]];

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

    context(@"valid object arguments on push registration", ^{
        __block BOOL wasExpectedResult = NO;

        beforeEach ( ^{
            wasExpectedResult = NO;
		});

        afterEach ( ^{
            [[theValue(wasExpectedResult) should] beTrue];
		});

        it(@"should have basic auth headers in the request", ^{

            [PCFPushPersistentStorage setRequestHeaders:nil];

            [NSURLConnection stub:@selector(pcfPushSendAsynchronousRequestWrapper:queue:completionHandler:) withBlock:^id(NSArray *params) {
                NSURLRequest *request = params[0];

                [[request.allHTTPHeaderFields[@"Authorization"] should] equal:[@"Basic  " stringByAppendingString:helper.base64AuthString1]];

                __block NSHTTPURLResponse *newResponse;

                [[request.HTTPMethod should] equal:@"POST"];

                newResponse = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200 HTTPVersion:nil headerFields:nil];

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

        it(@"should add configurable headers to the request without affecting the basic auth header", ^{

            [PCFPushPersistentStorage setRequestHeaders:@{ @"CHIPMUNKS":@"SUPER CUTE", @"RABBITS":@"THEY EAT YOUR GARDEN", @"Basic":@"Should be ignored" } ];

            [NSURLConnection stub:@selector(pcfPushSendAsynchronousRequestWrapper:queue:completionHandler:) withBlock:^id(NSArray *params) {
                NSURLRequest *request = params[0];

                [[request.allHTTPHeaderFields[@"Authorization"] should] equal:[@"Basic  " stringByAppendingString:helper.base64AuthString1]];
                [[request.allHTTPHeaderFields[@"CHIPMUNKS"] should] equal:@"SUPER CUTE"];
                [[request.allHTTPHeaderFields[@"RABBITS"] should] equal:@"THEY EAT YOUR GARDEN"];

                __block NSHTTPURLResponse *newResponse;

                [[request.HTTPMethod should] equal:@"POST"];

                newResponse = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200 HTTPVersion:nil headerFields:nil];

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

        it(@"should ignore custom headers with dumb values", ^{

            [PCFPushPersistentStorage setRequestHeaders:@{ @"NOT A STRING VALUE":@(YES) }];

            [NSURLConnection stub:@selector(pcfPushSendAsynchronousRequestWrapper:queue:completionHandler:) withBlock:^id(NSArray *params) {
                NSURLRequest *request = params[0];

                [[request.allHTTPHeaderFields[@"Authorization"] should] equal:[@"Basic  " stringByAppendingString:helper.base64AuthString1]];
                [[request.allHTTPHeaderFields[@"NOT A STRING VALUE"] should] beNil];

                __block NSHTTPURLResponse *newResponse;

                [[request.HTTPMethod should] equal:@"POST"];

                newResponse = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200 HTTPVersion:nil headerFields:nil];

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

    describe(@"unregistration", ^{

        __block BOOL wasExpectedResult = NO;

        beforeEach ( ^{
            wasExpectedResult = NO;
        });

        afterEach ( ^{
            [[theValue(wasExpectedResult) should] beTrue];
        });

        it(@"should let you unregister successfully", ^{

            [PCFPushPersistentStorage setRequestHeaders:@{ @"RACCOONS":@"REALLY RUN THE CITY", @"SQUIRRELS":@"THINK THEY ARE NUTS", @"Basic":@"Should be ignored" } ];

            [NSURLConnection stub:@selector(pcfPushSendAsynchronousRequestWrapper:queue:completionHandler:) withBlock:^id(NSArray *params) {
                NSURLRequest *request = params[0];

                [[request.allHTTPHeaderFields[@"Authorization"] should] equal:[@"Basic  " stringByAppendingString:helper.base64AuthString1]];
                [[request.allHTTPHeaderFields[@"RACCOONS"] should] equal:@"REALLY RUN THE CITY"];
                [[request.allHTTPHeaderFields[@"SQUIRRELS"] should] equal:@"THINK THEY ARE NUTS"];

                __block NSHTTPURLResponse *newResponse;

                [[request.HTTPMethod should] equal:@"DELETE"];

                newResponse = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200 HTTPVersion:nil headerFields:nil];

                CompletionHandler handler = params[2];
                handler(newResponse, nil, nil);
                return nil;
            }];

            [PCFPushURLConnection unregisterDeviceID:helper.backEndDeviceId
                                          parameters:helper.params
                                             success:^(NSURLResponse *response, NSData *data) {
                                                 wasExpectedResult = YES;
                                             }
                                             failure:^(NSError *error) {
                                                 wasExpectedResult = NO;
                                             }];
        });

        it(@"should handle failed unregistrations", ^{

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

            [PCFPushURLConnection unregisterDeviceID:helper.backEndDeviceId
                                          parameters:helper.params
                                             success:^(NSURLResponse *response, NSData *data) {
                                                 wasExpectedResult = NO;
                                             }
                                             failure:^(NSError *error) {
                                                 wasExpectedResult = YES;
                                             }];
        });
    });

    describe(@"update registrations", ^{

        __block BOOL wasExpectedResult = NO;

        beforeEach ( ^{
            wasExpectedResult = NO;
        });

        afterEach ( ^{
            [[theValue(wasExpectedResult) should] beTrue];
        });

        it(@"should let you update your push registration successfully", ^{

            [PCFPushPersistentStorage setRequestHeaders:@{ @"SNAZZY":@"RING TONE", @"Basic":@"Should be ignored" } ];

            [NSURLConnection stub:@selector(pcfPushSendAsynchronousRequestWrapper:queue:completionHandler:) withBlock:^id(NSArray *params) {
                NSURLRequest *request = params[0];

                [[request.allHTTPHeaderFields[@"Authorization"] should] equal:[@"Basic  " stringByAppendingString:helper.base64AuthString1]];
                [[request.allHTTPHeaderFields[@"SNAZZY"] should] equal:@"RING TONE"];

                __block NSHTTPURLResponse *newResponse;

                [[request.HTTPMethod should] equal:@"PUT"];

                newResponse = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200 HTTPVersion:nil headerFields:nil];
                CompletionHandler handler = params[2];
                handler(newResponse, nil, nil);
                return nil;
            }];

            [PCFPushURLConnection updateRegistrationWithDeviceID:helper.backEndDeviceId
                                                      parameters:helper.params
                                                     deviceToken:helper.apnsDeviceToken
                    success:^(NSURLResponse *response, NSData *data) {
                        wasExpectedResult = YES;
                    }
                    failure:^(NSError *error) {
                        wasExpectedResult = NO;
                    }];
        });

        it(@"should handle failed push update registrations", ^{

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

            [PCFPushURLConnection updateRegistrationWithDeviceID:helper.backEndDeviceId
                                                      parameters:helper.params
                                                     deviceToken:helper.apnsDeviceToken
                    success:^(NSURLResponse *response, NSData *data) {
                        wasExpectedResult = NO;
                    }
                    failure:^(NSError *error) {
                        wasExpectedResult = YES;
                    }];
        });
    });
});

SPEC_END
