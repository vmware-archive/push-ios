//
//  OmniaPushSDKSpec.mm
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-02-14.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import "OmniaPushSDK.h"
#import "OmniaPushAppDelegateProxy.h"
#import "OmniaSpecHelper.h"
#import "OmniaPushPersistentStorage.h"
#import "OmniaPushAPNSRegistrationRequestOperation.h"
#import "OmniaPushRegistrationCompleteOperation.h"
#import "OmniaPushRegistrationFailedOperation.h"
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
        [helper setupRegistrationRequestOperationWithNotificationTypes:testNotificationTypes];
        [helper setupQueues];
        previousAppDelegate = helper.applicationDelegate;
    });
    
    afterEach(^{
        previousAppDelegate = nil;
        [helper resetSingleton];
        [helper reset];
        helper = nil;
        sdk = nil;
    });
    
    describe(@"registration with bad arguments", ^{
        
        beforeEach(^{
            [helper setupApplicationForSuccessfulRegistrationWithNotificationTypes:testNotificationTypes];
            [helper setupApplicationDelegateForSuccessfulRegistration];
            [helper setApplicationInSingleton];
        });
                   
        it(@"should require a parameters object", ^{
            ^{sdk = [OmniaPushSDK registerWithParameters:nil];}
                should raise_exception([NSException class]);
            sdk should be_nil;
        });
    });

    describe(@"successful registration", ^{
        
        beforeEach(^{
            [helper setupApplicationForSuccessfulRegistrationWithNotificationTypes:testNotificationTypes];
            [helper setupApplicationDelegateForSuccessfulRegistration];
            [helper setApplicationInSingleton];
            [registrationHelper setupBackEndForSuccessfulRegistration];

            sdk = [OmniaPushSDK registerWithParameters:helper.params];
            sdk should_not be_nil;
            
            [helper.workerQueue drain];
        });
        
        it(@"should handle successful registrations from APNS", ^{
            helper.application should have_received(@selector(registerForRemoteNotificationTypes:));
            helper.applicationDelegate should have_received("application:didRegisterForRemoteNotificationsWithDeviceToken:");
            [helper.workerQueue didFinishOperation:[OmniaPushAPNSRegistrationRequestOperation class]] should be_truthy;
            [helper.workerQueue didFinishOperation:[OmniaPushRegistrationCompleteOperation class]] should be_truthy;
            [helper.workerQueue didFinishOperation:[OmniaPushRegistrationFailedOperation class]] should be_falsy;
            [helper.storage loadAPNSDeviceToken] should equal(helper.apnsDeviceToken);
        });

        it(@"should restore the application delegate after tearing down", ^{
            SEL teardownSelector = sel_registerName("teardown");
            [OmniaPushSDK performSelector:teardownSelector];
            UIApplication *app = (UIApplication*)(helper.application);
            app.delegate should be_same_instance_as(previousAppDelegate);
        });
    });
    
    describe(@"successful registration with listener", ^{
        
        it(@"should call the listener after successful registration from APNS", ^{
            [helper setupApplicationForSuccessfulRegistrationWithNotificationTypes:testNotificationTypes];
            [helper setupApplicationDelegateForSuccessfulRegistration];
            [helper setApplicationInSingleton];
            [registrationHelper setupBackEndForSuccessfulRegistration];
            
            id listener = fake_for(@protocol(OmniaPushRegistrationListener));
            listener stub_method("registrationSucceeded");
            
            sdk = [OmniaPushSDK registerWithParameters:helper.params listener:listener];
            sdk should_not be_nil;
            
            [helper.workerQueue drain];
        
            helper.application should have_received(@selector(registerForRemoteNotificationTypes:));
            helper.applicationDelegate should have_received("application:didRegisterForRemoteNotificationsWithDeviceToken:");
            [helper.workerQueue didFinishOperation:[OmniaPushAPNSRegistrationRequestOperation class]] should be_truthy;
            [helper.workerQueue didFinishOperation:[OmniaPushRegistrationCompleteOperation class]] should be_truthy;
            [helper.workerQueue didFinishOperation:[OmniaPushRegistrationFailedOperation class]] should be_falsy;
            [helper.storage loadAPNSDeviceToken] should equal(helper.apnsDeviceToken);
            listener should have_received("registrationSucceeded");
        });
    });
    
    describe(@"failed registration", ^{

        __block NSError *testError;

        beforeEach(^{
            testError = [NSError errorWithDomain:@"Some boring error" code:0 userInfo:nil];
            [helper setupApplicationForFailedRegistrationWithNotificationTypes:TEST_NOTIFICATION_TYPES error:testError];
            [helper setupApplicationDelegateForFailedRegistrationWithError:testError];
            [helper setApplicationInSingleton];
            
            sdk = [OmniaPushSDK registerWithParameters:helper.params];
            sdk should_not be_nil;
            
            [helper.workerQueue drain];
        });
        
        afterEach(^{
            testError = nil;
        });
        
        it(@"should handle registration failures from APNS", ^{
            helper.application should have_received(@selector(registerForRemoteNotificationTypes:));
            helper.applicationDelegate should have_received("application:didFailToRegisterForRemoteNotificationsWithError:");
            [helper.workerQueue didFinishOperation:[OmniaPushAPNSRegistrationRequestOperation class]] should be_truthy;
            [helper.workerQueue didFinishOperation:[OmniaPushRegistrationCompleteOperation class]] should be_falsy;
            [helper.workerQueue didFinishOperation:[OmniaPushRegistrationFailedOperation class]] should be_truthy;
            [helper.storage loadAPNSDeviceToken] should be_nil;
        });
        
        it(@"should restore the application delegate after tearing down", ^{
            SEL teardownSelector = sel_registerName("teardown");
            [OmniaPushSDK performSelector:teardownSelector];
            UIApplication *app = (UIApplication*)(helper.application);
            app.delegate should be_same_instance_as(previousAppDelegate);
        });
    });
    
    describe(@"failed registration with a listener", ^{
        
        __block NSError *testError;
        
        it(@"should call the listener after registration fails", ^{
            testError = [NSError errorWithDomain:@"Some boring error" code:0 userInfo:nil];
            [helper setupApplicationForFailedRegistrationWithNotificationTypes:TEST_NOTIFICATION_TYPES error:testError];
            [helper setupApplicationDelegateForFailedRegistrationWithError:testError];
            [helper setApplicationInSingleton];

            id listener = fake_for(@protocol(OmniaPushRegistrationListener));
            listener stub_method("registrationFailedWithError:").with(testError);

            sdk = [OmniaPushSDK registerWithParameters:helper.params listener:listener];
            sdk should_not be_nil;
            
            [helper.workerQueue drain];

            helper.application should have_received(@selector(registerForRemoteNotificationTypes:));
            helper.applicationDelegate should have_received("application:didFailToRegisterForRemoteNotificationsWithError:");
            [helper.workerQueue didFinishOperation:[OmniaPushAPNSRegistrationRequestOperation class]] should be_truthy;
            [helper.workerQueue didFinishOperation:[OmniaPushRegistrationCompleteOperation class]] should be_falsy;
            [helper.workerQueue didFinishOperation:[OmniaPushRegistrationFailedOperation class]] should be_truthy;
            [helper.storage loadAPNSDeviceToken] should be_nil;
            listener should have_received("registrationFailedWithError:");
        });
    });
});

SPEC_END
