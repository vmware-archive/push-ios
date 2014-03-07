//
//  OmniaPushSDKSpec.mm
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-02-14.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "OmniaPushSDK.h"
#import "OmniaSpecHelper.h"
#import "OmniaPushPersistentStorage.h"
#import "OmniaFakeOperationQueue.h"
#import "OmniaPushRegistrationParameters.h"
#import "OmniaRegistrationSpecHelper.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(OmniaPushSDKSpec)

describe(@"OmniaPushSDK", ^{
    
    __block OmniaPushSDK *sdk;
    __block OmniaSpecHelper *helper = nil;
    __block OmniaRegistrationSpecHelper *registrationHelper = nil;
    __block id<UIApplicationDelegate> previousAppDelegate;
    __block UIRemoteNotificationType testNotificationTypes = TEST_NOTIFICATION_TYPES;
    
    beforeEach(^{
        helper = [[OmniaSpecHelper alloc] init];
        registrationHelper = [[OmniaRegistrationSpecHelper alloc] initWithSpecHelper:nil];
        [helper setupApplication];
        [helper setupApplicationDelegate];
        [helper setupParametersWithNotificationTypes:testNotificationTypes];
        [helper setupQueues];
        previousAppDelegate = helper.applicationDelegate;
    });
    
    afterEach(^{
        previousAppDelegate = nil;
        [helper reset];
        helper = nil;
        sdk = nil;
    });
    
    describe(@"registration with bad arguments", ^{
        
        beforeEach(^{
            [helper setupApplicationForSuccessfulRegistrationWithNotificationTypes:testNotificationTypes];
            [helper setupApplicationDelegateForSuccessfulRegistration];
        });
                   
        it(@"should require a parameters object", ^{
            __block BOOL blockExecuted = NO;
            ^{[OmniaPushSDK registerWithParameters:nil success:^(NSURLResponse *response, id responseObject) {
                blockExecuted = YES;
            } failure:^(NSURLResponse *response, NSError *error) {
                blockExecuted = YES;
            }];}
                should raise_exception([NSException class]);
            blockExecuted should be_falsy;
        });
    });

    describe(@"successful registration", ^{
        
        beforeEach(^{
            [helper setupApplicationForSuccessfulRegistrationWithNotificationTypes:testNotificationTypes];
            [helper setupApplicationDelegateForSuccessfulRegistration];
            [registrationHelper setupBackEndForSuccessfulRegistration];

            __block BOOL successBlockExecuted = NO;
            [OmniaPushSDK registerWithParameters:helper.params success:^(NSURLResponse *response, id responseObject) {
                successBlockExecuted = YES;
            } failure:nil];
            successBlockExecuted should be_truthy;
            
            [helper.workerQueue drain];
        });
        
        it(@"should handle successful registrations from APNS", ^{
            helper.application should have_received(@selector(registerForRemoteNotificationTypes:));
            helper.applicationDelegate should have_received("application:didRegisterForRemoteNotificationsWithDeviceToken:");
            [OmniaPushPersistentStorage APNSDeviceToken] should equal(helper.apnsDeviceToken);
        });

        it(@"should restore the application delegate after tearing down", ^{
            SEL teardownSelector = sel_registerName("teardown");
            [OmniaPushSDK performSelector:teardownSelector];
            UIApplication *app = (UIApplication*)(helper.application);
            app.delegate should be_same_instance_as(previousAppDelegate);
        });
    });
    
    describe(@"failed registration", ^{

        __block NSError *testError;

        beforeEach(^{
            testError = [NSError errorWithDomain:@"Some boring error" code:0 userInfo:nil];
            [helper setupApplicationForFailedRegistrationWithNotificationTypes:TEST_NOTIFICATION_TYPES error:testError];
            [helper setupApplicationDelegateForFailedRegistrationWithError:testError];
            
            __block BOOL failureBlockExecuted = NO;
            [OmniaPushSDK registerWithParameters:helper.params
                                         success:nil
                                         failure:^(NSURLResponse *response, NSError *error) {
                                             failureBlockExecuted = YES;
                                         }];
            failureBlockExecuted should be_truthy;

            [helper.workerQueue drain];
        });
        
        afterEach(^{
            testError = nil;
        });
        
        it(@"should handle registration failures from APNS", ^{
            helper.application should have_received(@selector(registerForRemoteNotificationTypes:));
            helper.applicationDelegate should have_received("application:didFailToRegisterForRemoteNotificationsWithError:");
            [OmniaPushPersistentStorage APNSDeviceToken] should be_nil;
        });
        
        it(@"should restore the application delegate after tearing down", ^{
            SEL teardownSelector = sel_registerName("teardown");
            [OmniaPushSDK performSelector:teardownSelector];
            UIApplication *app = (UIApplication*)(helper.application);
            app.delegate should be_same_instance_as(previousAppDelegate);
        });
    });
    
    describe(@"failed registration with failure block", ^{
        
        __block NSError *testError;
        
        it(@"should call the listener after registration fails", ^{
            testError = [NSError errorWithDomain:@"Some boring error" code:0 userInfo:nil];
            [helper setupApplicationForFailedRegistrationWithNotificationTypes:TEST_NOTIFICATION_TYPES error:testError];
            [helper setupApplicationDelegateForFailedRegistrationWithError:testError];

            __block BOOL failureBlockExecuted = NO;
            [OmniaPushSDK registerWithParameters:helper.params
                                         success:nil
                                         failure:^(NSURLResponse *response, NSError *error) {
                                             failureBlockExecuted = YES;
                                         }];
            
            [helper.workerQueue drain];

            helper.application should have_received(@selector(registerForRemoteNotificationTypes:));
            helper.applicationDelegate should have_received("application:didFailToRegisterForRemoteNotificationsWithError:");
            [OmniaPushPersistentStorage APNSDeviceToken] should be_nil;
            failureBlockExecuted should be_truthy;
        });
    });
});

SPEC_END
