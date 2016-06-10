//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "Kiwi.h"

#import "PCFPushClient.h"
#import "PCFPushErrors.h"
#import "PCFPushAnalytics.h"
#import "PCFPushParameters.h"
#import "PCFPushSpecsHelper.h"
#import "PCFPushURLConnection.h"
#import "PCFPushAnalyticsEvent.h"
#import "NSObject+PCFJSONizable.h"
#import "PCFPushAnalyticsStorage.h"
#import "PCFPushPersistentStorage.h"
#import "PCFPushRegistrationPostRequestData.h"
#import "NSURLConnection+PCFBackEndConnection.h"

SPEC_BEGIN(PCFPushURLConnectionSpec)

typedef void (^RetryableRequestHandlerBlock)(NSURLResponse **, NSData **, NSError **);

describe(@"PCFPushBackEndConnection", ^{

    __block PCFPushSpecsHelper *helper;
    __block NSArray *events;

    beforeEach ( ^{
        [PCFPushClient resetSharedClient];
        helper = [[PCFPushSpecsHelper alloc] init];
        [helper setupParameters];
        [helper setupDefaultPersistedParameters];
        [helper setupAnalyticsStorage];
        [PCFPushPersistentStorage setServerVersion:@"1.3.2"];
        [PCFPushAnalytics logOpenedRemoteNotification:@"RECEIPT1" parameters:helper.params];
        [PCFPushAnalytics logTriggeredGeofenceId:27L locationId:81L parameters:helper.params];
        events = [helper.analyticsStorage managedObjectsWithEntityName:NSStringFromClass(PCFPushAnalyticsEvent.class)];
	});

    afterEach ( ^{
        [helper resetAnalyticsStorage];
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

    context(@"posting analytics events", ^{

        it(@"should require an events array", ^{
            [[theBlock( ^{
                [PCFPushURLConnection analyticsRequestWithEvents:nil parameters:helper.params  success:^(NSURLResponse *response, NSData *data) {} failure:^(NSError *error) {}];
            }) should] raiseWithName:NSInvalidArgumentException];
        });

        it(@"should require a non-empty events array", ^{
            [[theBlock( ^{
                [PCFPushURLConnection analyticsRequestWithEvents:@[] parameters:helper.params  success:^(NSURLResponse *response, NSData *data) {} failure:^(NSError *error) {}];
            }) should] raiseWithName:NSInvalidArgumentException];
        });

        it(@"should require a parameters object", ^{
            [[theBlock( ^{
                [PCFPushURLConnection analyticsRequestWithEvents:events parameters:nil  success:^(NSURLResponse *response, NSData *data) {} failure:^(NSError *error) {}];
            }) should] raiseWithName:NSInvalidArgumentException];
        });

        it(@"should not require a success block", ^{
            [helper setupAsyncRequestWithBlock:^(NSURLRequest *request, NSURLResponse **resultResponse, NSData **resultData, NSError **resultError) {
                *resultResponse = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@""]  statusCode:200 HTTPVersion:nil headerFields:nil];
            }];

            [[theBlock( ^{
                [PCFPushURLConnection analyticsRequestWithEvents:events parameters:helper.params success:nil failure:^(NSError *error) {}];
            }) shouldNot] raise];
        });

        it(@"should not require a failure block", ^{
            [helper setupAsyncRequestWithBlock:^(NSURLRequest *request, NSURLResponse **resultResponse, NSData **resultData, NSError **resultError) {
                *resultResponse = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@""]  statusCode:200 HTTPVersion:nil headerFields:nil];
            }];

            [[theBlock( ^{
                [PCFPushURLConnection analyticsRequestWithEvents:events parameters:helper.params success:^(NSURLResponse *response, NSData *data) {} failure:nil];
            }) shouldNot] raise];
        });

        it(@"should serialize event data into the POST message body and make a successful request", ^{
            __block BOOL wasExpectedResult = NO;
            __block BOOL didMakeRequest = NO;

            [PCFPushPersistentStorage setRequestHeaders:@{ @"ORANGE":@"KITTY", @"Basic":@"Should be ignored" } ];

            [helper setupAsyncRequestWithBlock:^(NSURLRequest *request, NSURLResponse **resultResponse, NSData **resultData, NSError **resultError) {
                didMakeRequest = YES;

                [[request.HTTPMethod should] equal:@"POST"];
                [[request.allHTTPHeaderFields[@"Authorization"] should] equal:[@"Basic  " stringByAppendingString:helper.base64AuthString1]];
                [[request.allHTTPHeaderFields[@"ORANGE"] should] equal:@"KITTY"];

                [[request.HTTPBody shouldNot] beNil];
                NSError *error;

                id json = [NSJSONSerialization JSONObjectWithData:request.HTTPBody options:0 error:&error];
                [[json shouldNot] beNil];
                [[error should] beNil];
                [[json[@"events"] shouldNot] beNil];
                [[json[@"events"] should] haveCountOf:2];

                id event2 = json[@"events"][0];
                [[event2[@"eventType"] should] equal:PCF_PUSH_EVENT_TYPE_PUSH_NOTIFICATION_OPENED];
                [[event2[@"receiptId"] should] equal:@"RECEIPT1"];
                [[event2[@"status"] should] beNil];

                id event1 = json[@"events"][1];
                [[event1[@"eventType"] should] equal:PCF_PUSH_EVENT_TYPE_PUSH_GEOFENCE_LOCATION_TRIGGER];
                [[event1[@"geofenceId"] should] equal:@"27"];
                [[event1[@"locationId"] should] equal:@"81"];
                [[event1[@"status"] should] beNil];

                *resultResponse = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@""]  statusCode:200 HTTPVersion:nil headerFields:nil];
            }];

            [PCFPushURLConnection analyticsRequestWithEvents:events parameters:helper.params success:^(NSURLResponse *response, NSData *data) {
                wasExpectedResult = YES;
            } failure:^(NSError *error) {
                fail(@"Should not have failed");
            }];
            [[theValue(wasExpectedResult) should] beTrue];
            [[theValue(didMakeRequest) should] beTrue];
        });


        it(@"should handle HTTP errors", ^{
            __block BOOL wasExpectedResult = NO;
            __block BOOL didMakeRequest = NO;

            [helper setupAsyncRequestWithBlock:^(NSURLRequest *request, NSURLResponse **resultResponse, NSData **resultData, NSError **resultError) {
                didMakeRequest = YES;

                *resultResponse = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@""]  statusCode:500 HTTPVersion:nil headerFields:nil];
            }];

            [PCFPushURLConnection analyticsRequestWithEvents:events parameters:helper.params success:^(NSURLResponse *response, NSData *data) {
                fail(@"Should not have succeeded");

            } failure:^(NSError *error) {
                wasExpectedResult = YES;
                [[error shouldNot] beNil];
            }];
            [[theValue(wasExpectedResult) should] beTrue];
            [[theValue(didMakeRequest) should] beTrue];
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

                [[request.HTTPMethod should] equal:@"GET"];
                [[request.URL.absoluteString should] endWithString:@"?timestamp=77777&device_uuid=DEVICE_UUID&platform=ios"];
                [[request.allHTTPHeaderFields[@"Authorization"] should] equal:[@"Basic  " stringByAppendingString:helper.base64AuthString1]];
                [[request.allHTTPHeaderFields[@"RABBIT SEASON"] should] equal:@"DUCK SEASON"];

                NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@""]  statusCode:200 HTTPVersion:nil headerFields:nil];

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

                [[request.HTTPMethod should] equal:@"GET"];
                [[request.URL.absoluteString should] endWithString:@"?timestamp=77777&device_uuid=DEVICE_UUID&platform=ios"];
                [[request.allHTTPHeaderFields[@"Authorization"] should] equal:[@"Basic  " stringByAppendingString:helper.base64AuthString1]];

                NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@""]  statusCode:400 HTTPVersion:nil headerFields:nil];

                CompletionHandler handler = params[2];
                handler(response, nil, nil);
                return nil;
            }];

            [PCFPushURLConnection geofenceRequestWithParameters:helper.params timestamp:77777L deviceUuid:@"DEVICE_UUID" success:^(NSURLResponse *response, NSData *data) {
                wasExpectedResult = NO;
            }  failure:^(NSError *error) {
                wasExpectedResult = YES;
            }];
        });
    });

    context(@"valid object arguments on new (POST) push registrations", ^{
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

                NSError *error;
                [[request.HTTPBody shouldNot] beNil];

                PCFPushRegistrationPostRequestData *requestData = [PCFPushRegistrationPostRequestData pcfPushFromJSONData:request.HTTPBody error:&error];
                [[requestData shouldNot] beNil];
                [[requestData.customUserId should] equal:helper.params.pushCustomUserId];

                newResponse = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@""]  statusCode:200 HTTPVersion:nil headerFields:nil];

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

        it(@"should omit the custom user ID field if the user doesn't provide one", ^{
            
            [PCFPushPersistentStorage setRequestHeaders:nil];
            
            [NSURLConnection stub:@selector(pcfPushSendAsynchronousRequestWrapper:queue:completionHandler:) withBlock:^id(NSArray *params) {
                NSURLRequest *request = params[0];
                
                NSHTTPURLResponse *newResponse;
                
                NSError *error;
                [[request.HTTPBody shouldNot] beNil];
                
                PCFPushRegistrationPostRequestData *requestData = [PCFPushRegistrationPostRequestData pcfPushFromJSONData:request.HTTPBody error:&error];
                [[requestData shouldNot] beNil];
                [[requestData.customUserId should] beNil];
                
                newResponse = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@""]  statusCode:200 HTTPVersion:nil headerFields:nil];
                
                CompletionHandler handler = params[2];
                handler(newResponse, nil, nil);
                return nil;
            }];

            helper.params.pushCustomUserId = @"";

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

                newResponse = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@""]  statusCode:200 HTTPVersion:nil headerFields:nil];

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

                newResponse = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@""]  statusCode:200 HTTPVersion:nil headerFields:nil];

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
                                                     [[theValue(error.code) should] equal:theValue(PCFPushBackEndAuthenticationError)];
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

                newResponse = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@""]  statusCode:200 HTTPVersion:nil headerFields:nil];

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

                newResponse = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@""]  statusCode:200 HTTPVersion:nil headerFields:nil];
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

    describe(@"version check", ^{

        __block BOOL wasExpectedResult = NO;
        __block RetryableRequestHandlerBlock handlerBlock;

        beforeEach (^{
            wasExpectedResult = NO;
            handlerBlock = nil;

            [PCFPushPersistentStorage setRequestHeaders:@{ @"OOH":@"LA LA", @"Basic":@"Should be ignored" } ];

            [helper setupAsyncRequestWithBlock:^(NSURLRequest *request, NSURLResponse **resultResponse, NSData **resultData, NSError **resultError) {

                [[request.allHTTPHeaderFields[@"Authorization"] should] beNil];
                [[request.allHTTPHeaderFields[@"OOH"] should] equal:@"LA LA"];
                [[request.HTTPMethod should] equal:@"GET"];

                if (handlerBlock) {
                    handlerBlock(resultResponse, resultData, resultError);
                }
            }];
        });

        afterEach ( ^{
            [[theValue(wasExpectedResult) should] beTrue];
        });

        it(@"should let you check the server version succcessfully", ^{

            handlerBlock = ^(NSURLResponse **response, NSData **data, NSError **error) {
                *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@""]  statusCode:200 HTTPVersion:nil headerFields:nil];
                *data = [@"{\"version\":\"1.3.3.7\"}" dataUsingEncoding:NSUTF8StringEncoding];
            };

            [PCFPushURLConnection versionRequestWithParameters:helper.params
                success:^(NSURLResponse *response, NSData *data) {
                    wasExpectedResult = YES;
                    [[data shouldNot] beNil];
                    NSError *error = nil;
                    id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                    [[error should] beNil];
                    [[json shouldNot] beNil];
                    [[json[@"version"] should] equal:@"1.3.3.7"];

                } oldVersion:^{
                    wasExpectedResult = NO;
                } retryableFailure:^(NSError *error) {
                    wasExpectedResult = NO;
                } fatalFailure:^(NSError *error) {
                    wasExpectedResult = NO;
                }];
        });

        it(@"should interpret 404 errors as an old server version", ^{

            handlerBlock = ^(NSURLResponse **response, NSData **data, NSError **error) {
                *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@""]  statusCode:404 HTTPVersion:nil headerFields:nil];
                *data = [@"404 not found dude" dataUsingEncoding:NSUTF8StringEncoding];
            };

            [PCFPushURLConnection versionRequestWithParameters:helper.params
                success:^(NSURLResponse *response, NSData *data) {
                    wasExpectedResult = NO;
                } oldVersion:^{
                    wasExpectedResult = YES;
                } retryableFailure:^(NSError *error) {
                    wasExpectedResult = NO;
                } fatalFailure:^(NSError *error) {
                    wasExpectedResult = NO;
                }];
        });

        it(@"should interpret crazy authentication errors as fatal errors", ^{

            handlerBlock = ^(NSURLResponse **response, NSData **data, NSError **error) {
                *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorUserAuthenticationRequired userInfo:nil];
            };

            [PCFPushURLConnection versionRequestWithParameters:helper.params
                success:^(NSURLResponse *response, NSData *data) {
                    wasExpectedResult = NO;
                } oldVersion:^{
                    wasExpectedResult = NO;
                } retryableFailure:^(NSError *error) {
                    wasExpectedResult = NO;
                } fatalFailure:^(NSError *error) {
                    wasExpectedResult = YES;
                    [[error.domain should] equal:PCFPushErrorDomain];
                    [[theValue(error.code) should] equal:theValue(PCFPushBackEndAuthenticationError)];
                }];
        });

        it(@"should interpret connection errors as retryable errors", ^{

            handlerBlock = ^(NSURLResponse **response, NSData **data, NSError **error) {
                *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorNetworkConnectionLost userInfo:nil];
            };

            [PCFPushURLConnection versionRequestWithParameters:helper.params
                success:^(NSURLResponse *response, NSData *data) {
                    wasExpectedResult = NO;
                } oldVersion:^{
                    wasExpectedResult = NO;
                } retryableFailure:^(NSError *error) {
                    wasExpectedResult = YES;
                    [[error.domain should] equal:NSURLErrorDomain];
                    [[theValue(error.code) should] equal:theValue(NSURLErrorNetworkConnectionLost)];
                } fatalFailure:^(NSError *error) {
                    wasExpectedResult = NO;
                }];
        });

        it(@"should interpret other 4xx errors as fatal server errors", ^{

            handlerBlock = ^(NSURLResponse **response, NSData **data, NSError **error) {
                *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@""]  statusCode:401 HTTPVersion:nil headerFields:nil];
                *data = [@"401 not authorized dude" dataUsingEncoding:NSUTF8StringEncoding];
            };

            [PCFPushURLConnection versionRequestWithParameters:helper.params
                success:^(NSURLResponse *response, NSData *data) {
                    wasExpectedResult = NO;
                } oldVersion:^{
                    wasExpectedResult = NO;
                } retryableFailure:^(NSError *error) {
                    wasExpectedResult = NO;
                } fatalFailure:^(NSError *error) {
                    wasExpectedResult = YES;
                    [[error.domain should] equal:PCFPushErrorDomain];
                    [[theValue(error.code) should] equal:theValue(PCFPushBackEndConnectionFailedHTTPStatusCode)];
                }];
        });

        it(@"should interpret other HTTP errors as retryable server errors", ^{

            handlerBlock = ^(NSURLResponse **response, NSData **data, NSError **error) {
                *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@""]  statusCode:500 HTTPVersion:nil headerFields:nil];
                *data = [@"500 the server is flipping out dude" dataUsingEncoding:NSUTF8StringEncoding];
            };

            [PCFPushURLConnection versionRequestWithParameters:helper.params
                success:^(NSURLResponse *response, NSData *data) {
                    wasExpectedResult = NO;
                } oldVersion:^{
                    wasExpectedResult = NO;
                } retryableFailure:^(NSError *error) {
                    wasExpectedResult = YES;
                    [[error shouldNot] beNil];
                } fatalFailure:^(NSError *error) {
                    wasExpectedResult = NO;
                }];
        });

        it(@"should consider nil responses and nil errors as retryable errors", ^{

            [PCFPushURLConnection versionRequestWithParameters:helper.params
                success:^(NSURLResponse *response, NSData *data) {
                    wasExpectedResult = NO;
                } oldVersion:^{
                    wasExpectedResult = NO;
                } retryableFailure:^(NSError *error) {
                    wasExpectedResult = YES;
                    [[error.domain should] equal:PCFPushErrorDomain];
                    [[theValue(error.code) should] equal:theValue(PCFPushBackEndConnectionEmptyErrorAndResponse)];
                } fatalFailure:^(NSError *error) {
                    wasExpectedResult = NO;
                }];
        });
    });

    describe(@"retrying version requests", ^{

        __block BOOL wasExpectedResult;
        __block int numberOfRequestsExecuted;
        __block NSMutableArray *handlerBlocks;
        __block void (^addHandlerBlock)(RetryableRequestHandlerBlock);
        __block RetryableRequestHandlerBlock successfulCall;
        __block RetryableRequestHandlerBlock oldVersionCall;
        __block RetryableRequestHandlerBlock failedCall;
        __block RetryableRequestHandlerBlock fatalCall;

        beforeEach ( ^{
            wasExpectedResult = NO;
            numberOfRequestsExecuted = 0;
            handlerBlocks = [NSMutableArray array];
            addHandlerBlock = ^(RetryableRequestHandlerBlock handlerBlock) {
                [handlerBlocks addObject:[handlerBlock copy]];
            };

            successfulCall = ^(NSURLResponse **response, NSData **data, NSError **error) {
                *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@""]  statusCode:200 HTTPVersion:nil headerFields:nil];
                *data = [@"{\"version\":\"1.3.3.7\"}" dataUsingEncoding:NSUTF8StringEncoding];
            };

            failedCall = ^(NSURLResponse **response, NSData **data, NSError **error) {
                *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@""]  statusCode:500 HTTPVersion:nil headerFields:nil];
                *data = [@"Transient error" dataUsingEncoding:NSUTF8StringEncoding];
            };

            fatalCall = ^(NSURLResponse **response, NSData **data, NSError **error) {
                *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@""]  statusCode:418 HTTPVersion:nil headerFields:nil];
                *data = [@"I'm a teapot" dataUsingEncoding:NSUTF8StringEncoding];
            };

            oldVersionCall = ^(NSURLResponse **response, NSData **data, NSError **error) {
                *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@""]  statusCode:404 HTTPVersion:nil headerFields:nil];
                *data = [@"404 error chumps" dataUsingEncoding:NSUTF8StringEncoding];
            };

            [PCFPushPersistentStorage setRequestHeaders:@{ @"OOH":@"LA LA", @"Basic":@"Should be ignored" } ];

            [NSURLConnection stub:@selector(pcfPushSendAsynchronousRequestWrapper:queue:completionHandler:) withBlock:^id(NSArray *params) {
                numberOfRequestsExecuted += 1;
                NSURLRequest *request = params[0];

                [[request.allHTTPHeaderFields[@"Authorization"] should] beNil];
                [[request.allHTTPHeaderFields[@"OOH"] should] equal:@"LA LA"];
                [[request.HTTPMethod should] equal:@"GET"];

                NSHTTPURLResponse *response = nil;
                NSData *data = nil;
                NSError *error = nil;

                RetryableRequestHandlerBlock handlerBlock = (RetryableRequestHandlerBlock) handlerBlocks[0];
                if (handlerBlock) {
                    [handlerBlocks removeObjectAtIndex:0];
                    handlerBlock(&response, &data, &error);
                }

                CompletionHandler handler = params[2];
                handler(response, data, error);
                return nil;
            }];
        });

        afterEach ( ^{
            [[theValue(wasExpectedResult) should] beTrue];
        });

        it(@"should return a version data string after a successful request", ^{

            addHandlerBlock(successfulCall);

            [PCFPushURLConnection versionRequestWithParameters:helper.params success:^(NSString *version){
                wasExpectedResult = YES;
                [[version should] equal:@"1.3.3.7"];
            } oldVersion:^{
                wasExpectedResult = NO;
            } failure:^(NSError *error){
                wasExpectedResult = NO;
            }];

            [[theValue(numberOfRequestsExecuted) should] equal:theValue(1)];
        });

        it(@"should return an error if the result data doesn't parse", ^{

            addHandlerBlock(^(NSURLResponse **response, NSData **data, NSError **error) {
                *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@""]  statusCode:200 HTTPVersion:nil headerFields:nil];
                *data = [@"NOT JSON" dataUsingEncoding:NSUTF8StringEncoding];
            });

            [PCFPushURLConnection versionRequestWithParameters:helper.params success:^(NSString *version) {
                wasExpectedResult = NO;
            } oldVersion:^{
                wasExpectedResult = NO;
            } failure:^(NSError *error) {
                wasExpectedResult = YES;
                [[error.domain should] equal:PCFPushErrorDomain];
                [[theValue(error.code) should] equal:theValue(PCFPushBackEndDataUnparseable)];
            }];

            [[theValue(numberOfRequestsExecuted) should] equal:theValue(1)];
        });

        it(@"should return an old version error if the server returns a 404 error", ^{

            addHandlerBlock(oldVersionCall);

            [PCFPushURLConnection versionRequestWithParameters:helper.params success:^(NSString *version) {
                wasExpectedResult = NO;
            } oldVersion:^{
                wasExpectedResult = YES;
            } failure:^(NSError *error) {
                wasExpectedResult = NO;
            }];

            [[theValue(numberOfRequestsExecuted) should] equal:theValue(1)];
        });

        it(@"should return a fatal error if the server returns another 4xx error", ^{

            addHandlerBlock(fatalCall);

            [PCFPushURLConnection versionRequestWithParameters:helper.params success:^(NSString *version) {
                wasExpectedResult = NO;
            } oldVersion:^{
                wasExpectedResult = NO;
            } failure:^(NSError *error) {
                wasExpectedResult = YES;
                [[error.domain should] equal:PCFPushErrorDomain];
                [[theValue(error.code) should] equal:theValue(PCFPushBackEndConnectionFailedHTTPStatusCode)];
            }];

            [[theValue(numberOfRequestsExecuted) should] equal:theValue(1)];
        });

        it(@"should retry three times and then return an error if there is some kind of transient error", ^{

            addHandlerBlock(failedCall);
            addHandlerBlock(failedCall);
            addHandlerBlock(failedCall);

            [PCFPushURLConnection versionRequestWithParameters:helper.params success:^(NSString *version) {
                wasExpectedResult = NO;
            } oldVersion:^{
                wasExpectedResult = NO;
            } failure:^(NSError *error) {
                wasExpectedResult = YES;
                [[error.domain should] equal:PCFPushErrorDomain];
                [[theValue(error.code) should] equal:theValue(PCFPushBackEndConnectionFailedHTTPStatusCode)];
            }];

            [[theValue(numberOfRequestsExecuted) should] equal:theValue(3)];
        });

        it(@"should retry three times and then return the version is there are two errors and a successful call", ^{

            addHandlerBlock(failedCall);
            addHandlerBlock(failedCall);
            addHandlerBlock(successfulCall);

            [PCFPushURLConnection versionRequestWithParameters:helper.params success:^(NSString *version) {
                wasExpectedResult = YES;
                [[version should] equal:@"1.3.3.7"];
            } oldVersion:^{
                wasExpectedResult = NO;
            } failure:^(NSError *error) {
                wasExpectedResult = NO;
            }];

            [[theValue(numberOfRequestsExecuted) should] equal:theValue(3)];
        });

        it(@"should retry three times and then return an old version if there are two errors and then a 404", ^{

            addHandlerBlock(failedCall);
            addHandlerBlock(failedCall);
            addHandlerBlock(oldVersionCall);

            [PCFPushURLConnection versionRequestWithParameters:helper.params success:^(NSString *version) {
                wasExpectedResult = NO;
            } oldVersion:^{
                wasExpectedResult = YES;
            } failure:^(NSError *error) {
                wasExpectedResult = NO;
            }];

            [[theValue(numberOfRequestsExecuted) should] equal:theValue(3)];
        });
    });
});

SPEC_END
