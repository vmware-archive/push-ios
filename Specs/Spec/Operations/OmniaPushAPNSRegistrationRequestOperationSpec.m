//
//  OmniaPushAPNSRegistrationRequestOperationSpec.mm
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-02-14.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#import "Kiwi.h"

#import "OmniaPushAPNSRegistrationRequestOperationTest.h"
#import "OmniaPushRegistrationParameters.h"
#import "OmniaFakeOperationQueue.h"
#import "OmniaSpecHelper.h"
#import "OmniaPushSDKTest.h"

SPEC_BEGIN(OmniaPushAPNSRegistrationRequestOperationSpec)

describe(@"OmniaPushAPNSRegistrationRequestOperation", ^{
    
    __block OmniaSpecHelper *helper;

    beforeEach(^{
        helper = [[OmniaSpecHelper alloc] init];
        [helper setupApplication];
        [helper setupApplicationDelegate];
        [helper setupParametersWithNotificationTypes:TEST_NOTIFICATION_TYPES];
        [helper setupQueues];
        [OmniaPushSDK setWorkerQueue:helper.workerQueue];
    });
    
    afterEach(^{
        [helper reset];
        helper = nil;
    });

    context(@"contructing with invalid arguments", ^{
        
        it(@"should require parameters", ^{
            [[theBlock(^{NSOperation *operation __unused = [[OmniaPushAPNSRegistrationRequestOperation alloc] initWithApplication:nil remoteNotificationTypes:0 success:nil failure:nil];})
              should] raise];
        });

        it(@"should require an application", ^{
            [[theBlock(^{NSOperation *operation __unused = [[OmniaPushAPNSRegistrationRequestOperation alloc] initWithApplication:nil remoteNotificationTypes:helper.params.remoteNotificationTypes success:nil failure:nil];})
              should] raise];
        });

    });
    
    context(@"constructing with valid arguments", ^{
        
        __block OmniaPushAPNSRegistrationRequestOperation *operation;
        
        beforeEach(^{
            operation = [[OmniaPushAPNSRegistrationRequestOperation alloc] initWithApplication:helper.application
                                                                       remoteNotificationTypes:helper.params.remoteNotificationTypes
                                                                                       success:^(NSData *devToken) {}
                                                                                       failure:^(NSError *error) {}];
        });
        
        it(@"should produce a valid instance", ^{
            [[operation shouldNot] beNil];
        });
        
        it(@"should retain its arguments as properties", ^{
            [[theValue(operation.remoteNotificationTypes) should] equal:theValue(helper.params.remoteNotificationTypes)];
            [[operation.application should] beIdenticalTo:helper.application];
        });
    });
    
    context(@"registration", ^{
        
        __block NSError *testError = [NSError errorWithDomain:@"Some lame error" code:0 userInfo:nil];
        
        it(@"should be able to register successfully", ^{
            [helper setupApplicationForSuccessfulRegistrationWithNotificationTypes:TEST_NOTIFICATION_TYPES];
            [helper setupApplicationDelegateForSuccessfulRegistration];
            [[helper.application should] receive:@selector(registerForRemoteNotificationTypes:)];
            [[(id)helper.applicationDelegate should] receive:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:)];
            
            NSOperation *operation = [[OmniaPushAPNSRegistrationRequestOperation alloc] initWithApplication:helper.application
                                                                                    remoteNotificationTypes:helper.params.remoteNotificationTypes
                                                                                                    success:^(NSData *devToken) {}
                                                                                                    failure:^(NSError *error) {}];
            [[OmniaPushSDK omniaPushOperationQueue] addOperation:operation];
            [[theValue([[OmniaPushSDK omniaPushOperationQueue] operationCount]) should] beZero];
        });
        
        it(@"should be able to fail registration", ^{
            [helper setupApplicationForFailedRegistrationWithNotificationTypes:TEST_NOTIFICATION_TYPES error:testError];
            [helper setupApplicationDelegateForFailedRegistrationWithError:testError];
            [[helper.application should] receive:@selector(registerForRemoteNotificationTypes:)];
            [[(id)helper.applicationDelegate should] receive:@selector(application:didFailToRegisterForRemoteNotificationsWithError:)];
            
            NSOperation *operation = [[OmniaPushAPNSRegistrationRequestOperation alloc] initWithApplication:helper.application
                                                                                    remoteNotificationTypes:helper.params.remoteNotificationTypes
                                                                                                    success:^(NSData *devToken) {}
                                                                                                    failure:^(NSError *error) {}];

            [helper.workerQueue addOperation:operation];
            [[theValue([[OmniaPushSDK omniaPushOperationQueue] operationCount]) should] beZero];
        });
    });

});

SPEC_END
