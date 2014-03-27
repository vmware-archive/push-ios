//
//  CFPushBackEndRegistrationRequestImplSpec.mm
//  CFPushSDK
//
//  Created by Rob Szumlakowski on 2014-02-14.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "Kiwi.h"

#import "NSURLConnection+CFAsync2Sync.h"
#import "NSURLConnection+CFPushBackEndConnection.h"
#import "CFPushErrors.h"
#import "CFSpecHelper.h"

SPEC_BEGIN(CFPushBackEndConnectionSpec)

describe(@"CFPushBackEndConnection", ^{
    
    __block CFSpecHelper *helper;

    beforeEach(^{
        helper = [[CFSpecHelper alloc] init];
        [helper setupParametersWithNotificationTypes:TEST_NOTIFICATION_TYPES];
    });
    
    afterEach(^{
        [helper reset];
        helper = nil;
    });
    
    context(@"registration bad object arguments", ^{
        
        it(@"should require an APNS device token", ^{
            [[theBlock(^{[NSURLConnection cf_registerWithParameters:helper.params
                                                        devToken:nil
                                                         success:^(NSURLResponse *response, NSData *data) {}
                                                         failure:^(NSError *error) {}];})
              should] raise];
        });
        
        it(@"should require a registration parameters", ^{
            [[theBlock(^{[NSURLConnection cf_registerWithParameters:nil
                                                        devToken:helper.apnsDeviceToken
                                                         success:^(NSURLResponse *response, NSData *data) {}
                                                         failure:^(NSError *error) {}];})
              should] raise];
        });
        
        it(@"should require a success block", ^{
            [[theBlock(^{[NSURLConnection cf_registerWithParameters:helper.params
                                                        devToken:helper.apnsDeviceToken
                                                         success:nil
                                                         failure:^(NSError *error) {}];})
              should] raise];
        });
        
        it(@"should require a failure block", ^{
            [[theBlock(^{[NSURLConnection cf_registerWithParameters:helper.params
                                                        devToken:helper.apnsDeviceToken
                                                         success:^(NSURLResponse *response, NSData *data) {}
                                                         failure:nil];})
              should] raise];
        });
    });
    
    context(@"unregistration bad object arguments", ^{
        it(@"should not require a device ID", ^{
            [[theBlock(^{[NSURLConnection cf_unregisterDeviceID:nil
                                                     success:^(NSURLResponse *response, NSData *data) {}
                                                     failure:^(NSError *error) {}];})
              shouldNot] raise];
        });
        
        it(@"should require a success block", ^{
            [[theBlock(^{[NSURLConnection cf_unregisterDeviceID:@"Fake Device ID"
                                                     success:nil
                                                     failure:^(NSError *error) {}];})
              should] raise];
        });
        
        it(@"should require a failure block", ^{
            [[theBlock(^{[NSURLConnection cf_unregisterDeviceID:@"Fake Device ID"
                                                     success:^(NSURLResponse *response, NSData *data) {}
                                                     failure:nil];})
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
            [NSURLConnection cf_registerWithParameters:helper.params
                                                 devToken:helper.apnsDeviceToken
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
