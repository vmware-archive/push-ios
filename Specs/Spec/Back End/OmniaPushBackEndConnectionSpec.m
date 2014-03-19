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
    });
    
    afterEach(^{
        [helper reset];
        helper = nil;
    });
    
    context(@"bad object arguments", ^{
        
        it(@"should require an APNS device token", ^{
            [[theBlock(^{[OmniaPushBackEndConnection sendRegistrationRequestOnQueue:helper.workerQueue
                                                          withParameters:helper.params
                                                                devToken:nil
                                                                 success:^(NSURLResponse *response, NSData *data) {}
                                                                 failure:^(NSURLResponse *response, NSError *error) {}];})
              should] raise];
        });
        
        it(@"should require a registration parameters", ^{
            [[theBlock(^{[OmniaPushBackEndConnection sendRegistrationRequestOnQueue:helper.workerQueue
                                                           withParameters:nil
                                                                 devToken:helper.apnsDeviceToken
                                                                  success:^(NSURLResponse *response, NSData *data) {}
                                                                  failure:^(NSURLResponse *response, NSError *error) {}];})
             should] raise];
        });
        
        it(@"should require a success block", ^{
            [[theBlock(^{[OmniaPushBackEndConnection sendRegistrationRequestOnQueue:helper.workerQueue
                                                          withParameters:helper.params
                                                                devToken:helper.apnsDeviceToken
                                                                 success:nil
                                                                 failure:^(NSURLResponse *response, NSError *error) {}];})
            should] raise];
        });
        
        it(@"should require a failure block", ^{
            [[theBlock(^{[OmniaPushBackEndConnection sendRegistrationRequestOnQueue:helper.workerQueue
                                                            withParameters:helper.params
                                                                  devToken:helper.apnsDeviceToken
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
    });
    
});

SPEC_END
