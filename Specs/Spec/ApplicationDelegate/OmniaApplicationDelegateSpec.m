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
#import "OmniaApplicationDelegate.h"
#import "OmniaPushRegistrationParameters.h"
#import "OmniaSpecHelper.h"
#import "OmniaPushSDKTest.h"

SPEC_BEGIN(OmniaApplicationDelegateSpec)

describe(@"OmniaApplicationDelegate", ^{
    
    __block OmniaSpecHelper *helper;

    beforeEach(^{
        helper = [[OmniaSpecHelper alloc] init];
        [helper setupApplication];
        [helper setupApplicationDelegate];
        [helper setupParametersWithNotificationTypes:TEST_NOTIFICATION_TYPES];
    });
    
    afterEach(^{
        [OmniaApplicationDelegate resetApplicationDelegate];
        [helper reset];
        helper = nil;
    });

    context(@"contructing with invalid arguments", ^{
        
        it(@"should require parameters", ^{
            [[theBlock(^{[[OmniaApplicationDelegate omniaApplicationDelegate] registerWithApplication:[UIApplication sharedApplication]
                                                                                                                remoteNotificationTypes:0
                                                                                                                                success:nil
                                                                                                                                failure:nil];})
              should] raise];
        });

        it(@"should require an application", ^{
            [[theBlock(^{[[OmniaApplicationDelegate omniaApplicationDelegate] registerWithApplication:nil
                                                                              remoteNotificationTypes:helper.params.remoteNotificationTypes
                                                                                              success:^(NSData *devToken) {}
                                                                                              failure:^(NSError *error) {}];})
              should] raise];
        });

    });
    
    context(@"registration", ^{
        
        __block NSError *testError = [NSError errorWithDomain:@"Some lame error" code:0 userInfo:nil];
        
        it(@"should be able to register successfully", ^{
            [helper setupApplicationForSuccessfulRegistrationWithNotificationTypes:TEST_NOTIFICATION_TYPES];
            [helper setupApplicationDelegateForSuccessfulRegistration];
            [[helper.application should] receive:@selector(registerForRemoteNotificationTypes:)];
            [[(id)helper.applicationDelegate should] receive:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:)];
            
            [[OmniaApplicationDelegate omniaApplicationDelegate] registerWithApplication:helper.application
                                                                 remoteNotificationTypes:helper.params.remoteNotificationTypes
                                                                                 success:^(NSData *devToken) {}
                                                                                 failure:^(NSError *error) {}];
        });
        
        it(@"should be able to fail registration", ^{
            [helper setupApplicationForFailedRegistrationWithNotificationTypes:TEST_NOTIFICATION_TYPES error:testError];
            [helper setupApplicationDelegateForFailedRegistrationWithError:testError];
            [[helper.application should] receive:@selector(registerForRemoteNotificationTypes:)];
            [[(id)helper.applicationDelegate should] receive:@selector(application:didFailToRegisterForRemoteNotificationsWithError:)];
            
            [[OmniaApplicationDelegate omniaApplicationDelegate] registerWithApplication:helper.application
                                                                 remoteNotificationTypes:helper.params.remoteNotificationTypes
                                                                                 success:^(NSData *devToken) {}
                                                                                 failure:^(NSError *error) {}];
        });
    });

});

SPEC_END
