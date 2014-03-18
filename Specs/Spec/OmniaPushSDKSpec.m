//
//  OmniaPushSDKSpec.mm
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-02-14.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "Kiwi.h"
#import "OmniaPushSDKTest.h"
#import "OmniaSpecHelper.h"
#import "OmniaPushPersistentStorage.h"
#import "OmniaFakeOperationQueue.h"
#import "OmniaPushRegistrationParameters.h"

SPEC_BEGIN(OmniaPushSDKSpec)

describe(@"OmniaPushSDK", ^{
    __block OmniaSpecHelper *helper = nil;
    __block id<UIApplicationDelegate> previousAppDelegate;
    __block UIRemoteNotificationType testNotificationTypes = TEST_NOTIFICATION_TYPES;
    
    beforeEach(^{
        helper = [[OmniaSpecHelper alloc] init];
        [helper setupApplication];
        [helper setupApplicationDelegate];
        [helper setupParametersWithNotificationTypes:testNotificationTypes];
        [helper setupQueues];
        [OmniaPushSDK setWorkerQueue:helper.workerQueue];
        previousAppDelegate = helper.applicationDelegate;
    });
    
    afterEach(^{
        previousAppDelegate = nil;
        [helper reset];
        helper = nil;
    });
    
    describe(@"registration with bad arguments", ^{
        
        beforeEach(^{
            [helper setupApplicationForSuccessfulRegistrationWithNotificationTypes:testNotificationTypes];
            [helper setupApplicationDelegateForSuccessfulRegistration];
        });
                   
        it(@"should require a parameters object", ^{
            __block BOOL blockExecuted = NO;
            [[^{[OmniaPushSDK registerWithParameters:nil success:^(NSURLResponse *response, id responseObject) {
                blockExecuted = YES;
            } failure:^(NSURLResponse *response, NSError *error) {
                blockExecuted = YES;
            }];}
              should] raise];
            [[theValue(blockExecuted) should] beFalse];
        });
    });

    describe(@"successful registration", ^{
        
        beforeEach(^{
            [helper setupApplicationForSuccessfulRegistrationWithNotificationTypes:testNotificationTypes];
            [helper setupApplicationDelegateForSuccessfulRegistration];

            __block BOOL successBlockExecuted = NO;
            [OmniaPushSDK registerWithParameters:helper.params success:^(NSURLResponse *response, id responseObject) {
                successBlockExecuted = YES;
            } failure:nil];
            [[theValue(successBlockExecuted) should] beTrue];
            
            [helper.workerQueue drain];
        });
        
        it(@"should handle successful registrations from APNS", ^{
            [[helper.application should] receive:@selector(registerForRemoteNotificationTypes:)];
            [[(id)helper.applicationDelegate should] receive:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:)];
            [[[OmniaPushPersistentStorage APNSDeviceToken] should] equal:helper.apnsDeviceToken];
        });

        it(@"should restore the application delegate after tearing down", ^{
            SEL teardownSelector = sel_registerName("teardown");
            [OmniaPushSDK performSelector:teardownSelector];
            UIApplication *app = (UIApplication*)(helper.application);
            [[(id)app.delegate should] equal:previousAppDelegate];
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
            [[theValue(failureBlockExecuted) should] beTrue];

            [helper.workerQueue drain];
        });
        
        afterEach(^{
            testError = nil;
        });
        
        it(@"should handle registration failures from APNS", ^{
            [[helper.application should] receive:@selector(registerForRemoteNotificationTypes:)];
            [[(id)helper.applicationDelegate should] receive:@selector(application:didFailToRegisterForRemoteNotificationsWithError:)];
            [[[OmniaPushPersistentStorage APNSDeviceToken] should] beNil];
        });
        
        it(@"should restore the application delegate after tearing down", ^{
            SEL teardownSelector = sel_registerName("teardown");
            [OmniaPushSDK performSelector:teardownSelector];
            UIApplication *app = (UIApplication*)(helper.application);
            [[(id)app.delegate should] equal:previousAppDelegate];
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

            [[helper.application should] receive:@selector(registerForRemoteNotificationTypes:)];
            [[(id)helper.applicationDelegate should] receive:@selector(application:didFailToRegisterForRemoteNotificationsWithError:)];
            [[[OmniaPushPersistentStorage APNSDeviceToken] should] beNil];
            [[theValue(failureBlockExecuted) should] beTrue];
        });
    });
});

SPEC_END
