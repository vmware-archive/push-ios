//
//  OmniaSpecHelper.mm
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-31.
//  Copyright (c) 2013 Omnia. All rights reserved.
//

#import "OmniaSpecHelper.h"
#import "OmniaPushSDK.h"
#import "OmniaPushAPNSRegistrationRequestOperation.h"
#import "OmniaPushAppDelegateProxy.h"
#import "OmniaPushAppDelegateProxyImpl.h"
#import "OmniaPushRegistrationListener.h"
#import "OmniaPushDebug.h"
#import "OmniaFakeOperationQueue.h"
#import "OmniaPushOperationQueueProvider.h"

#define DELAY_TIME_IN_SECONDS 1

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

static id<UIApplicationDelegate> applicationDelegate;
static NSProxy<OmniaPushAppDelegateProxy> *appDelegateProxy;
static id<OmniaPushRegistrationListener> appDelegateProxyRegistrationListener;
static id<OmniaPushRegistrationListener> sdkInstanceRegistrationListener;
static id<OmniaPushRegistrationListener> sdkRegistrationListener;
static OmniaPushAPNSRegistrationRequestOperation *registrationRequestOperation;
static NSData *deviceToken;
static UIApplication *application;
static dispatch_time_t DELAY_TIME = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(DELAY_TIME_IN_SECONDS * NSEC_PER_SEC));
static OmniaFakeOperationQueue *operationQueue;

# pragma mark - Spec Helper lifecycle

void setupOmniaSpecHelper() {
    deviceToken = [@"TEST DEVICE TOKEN" dataUsingEncoding:NSUTF8StringEncoding];
    application = [UIApplication sharedApplication];
}

void resetOmniaSpecHelper() {
    operationQueue = nil;
    [OmniaPushOperationQueueProvider setOperationQueue:nil];
    deviceToken = nil;
    application = nil;
    applicationDelegate = nil;
    appDelegateProxy = nil;
    appDelegateProxyRegistrationListener = nil;
    sdkInstanceRegistrationListener = nil;
    sdkRegistrationListener = nil;
    registrationRequestOperation = nil;
}

#pragma mark - Application helpers

UIApplication *setupApplication() {
    application = (UIApplication*) fake_for([UIApplication class]);
    return application;
}

void setupApplicationForSuccessfulRegistration(UIRemoteNotificationType notificationTypes) {
    application stub_method("registerForRemoteNotificationTypes:").with(notificationTypes).and_do(^(NSInvocation*) {
        [applicationDelegate application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
    });
}

void setupApplicationForFailedRegistration(UIRemoteNotificationType notificationTypes, NSError *error) {
    application stub_method("registerForRemoteNotificationTypes:").with(notificationTypes).and_do(^(NSInvocation*) {
        [applicationDelegate application:application didFailToRegisterForRemoteNotificationsWithError:error];
    });
}

UIApplication *getApplication() {
    return application;
}

#pragma mark - App Delegate Helpers

id<UIApplicationDelegate> setupApplicationDelegate() {
    applicationDelegate = fake_for(@protocol(UIApplicationDelegate));
    application stub_method("delegate").and_return(applicationDelegate);
    return applicationDelegate;
}

void setupApplicationDelegateForSuccessfulRegistration() {
    applicationDelegate stub_method("application:didRegisterForRemoteNotificationsWithDeviceToken:").with(application, deviceToken);;
}

void setupApplicationDelegateForFailedRegistration(NSError *error) {
    applicationDelegate stub_method("application:didFailToRegisterForRemoteNotificationsWithError:").with(application, error);
}

id<UIApplicationDelegate> getApplicationDelegate() {
    return applicationDelegate;
}

#pragma mark - App Delegate Proxy helpers

NSProxy<OmniaPushAppDelegateProxy>* setupAppDelegateProxy() {
    appDelegateProxy = [[OmniaPushAppDelegateProxyImpl alloc] initWithAppDelegate:applicationDelegate registrationRequest:registrationRequestOperation];
    return appDelegateProxy;
}

NSProxy<OmniaPushAppDelegateProxy>* getAppDelegateProxy() {
    return appDelegateProxy;
}

//#pragma mark - App Delegate Proxy Registration Listener helpers
//
//id<OmniaPushRegistrationListener> setupAppDelegateProxyRegistrationListener() {
//    appDelegateProxyRegistrationListener = fake_for(@protocol(OmniaPushRegistrationListener));
//    return appDelegateProxyRegistrationListener;
//}
//
//void setupAppDelegateProxyRegistrationListenerForSuccessfulRegistration() {
//    appDelegateProxyRegistrationListener stub_method("application:didRegisterForRemoteNotificationsWithDeviceToken:").with(application, deviceToken);
//}
//
//void setupAppDelegateProxyRegistrationListenerForFailedRegistration(NSError *error) {
//    appDelegateProxyRegistrationListener stub_method("application:didFailToRegisterForRemoteNotificationsWithError:").with(application, error);
//}
//
//id<OmniaPushRegistrationListener> getAppDelegateProxyRegistrationListener() {
//    return appDelegateProxyRegistrationListener;
//}
//
//#pragma mark - SDK Instance Registration Listener helpers
//
//id<OmniaPushRegistrationListener> setupSDKInstanceRegistrationListener() {
//    sdkInstanceRegistrationListener = fake_for(@protocol(OmniaPushRegistrationListener));
//    return sdkInstanceRegistrationListener;
//}
//
//void setupSDKInstanceRegistrationListenerForSuccessfulRegistration() {
//    sdkInstanceRegistrationListener stub_method("application:didRegisterForRemoteNotificationsWithDeviceToken:").with(application, deviceToken).and_do(^(NSInvocation*) {
//    });
//}
//
//void setupSDKInstanceRegistrationListenerForFailedRegistration(NSError *error) {
//    sdkInstanceRegistrationListener stub_method("application:didFailToRegisterForRemoteNotificationsWithError:").with(application, error).and_do(^(NSInvocation*) {
//    });
//}
//
//id<OmniaPushRegistrationListener> getSDKInstanceRegistrationListener() {
//    return sdkInstanceRegistrationListener;
//}
//
//#pragma mark - SDK Registration Listener helpers
//
//id<OmniaPushRegistrationListener> setupSDKRegistrationListener() {
//    sdkRegistrationListener = fake_for(@protocol(OmniaPushRegistrationListener));
//    return sdkRegistrationListener;
//}
//
//void setupSDKRegistrationListenerForSuccessfulRegistration() {
//    sdkRegistrationListener stub_method("application:didRegisterForRemoteNotificationsWithDeviceToken:").with(application, deviceToken).and_do(^(NSInvocation*) {
//    });
//}
//
//void setupSDKRegistrationListenerForFailedRegistration(NSError *error) {
//    sdkRegistrationListener stub_method("application:didFailToRegisterForRemoteNotificationsWithError:").with(application, error).and_do(^(NSInvocation*) {
//    });
//}
//
//id<OmniaPushRegistrationListener> getSDKRegistrationListener() {
//    return sdkRegistrationListener;
//}

#pragma mark - Registration Request helpers

OmniaPushAPNSRegistrationRequestOperation* setupRegistrationRequestOperation(UIRemoteNotificationType notificationTypes) {
    registrationRequestOperation = [[OmniaPushAPNSRegistrationRequestOperation alloc] initForRegistrationForRemoteNotificationTypes:notificationTypes application:application];
    return registrationRequestOperation;
}

//void setupRegistrationRequestOperationForSuccessfulRegistration(NSProxy<OmniaPushAppDelegateProxy> *appDelegateProxy) {
//    registrationRequestOperation stub_method("registerForRemoteNotificationTypes:").with(TEST_NOTIFICATION_TYPE).and_do(^(NSInvocation*) {
//        [appDelegateProxy application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
//    });
//}

//void setupRegistrationRequestOperationForFailedRegistration(NSProxy<OmniaPushAppDelegateProxy> *appDelegateProxy, NSError *error) {
//    registrationRequestOperation stub_method("registerForRemoteNotificationTypes:").with(TEST_NOTIFICATION_TYPE).and_do(^(NSInvocation*) {
//        [appDelegateProxy application:application didFailToRegisterForRemoteNotificationsWithError:error];
//    });
//}

//void setupRegistrationRequestOperationForSuccessfulAsynchronousRegistration(NSProxy<OmniaPushAppDelegateProxy> *appDelegateProxy, int delayInMilliseconds) {
//    registrationRequestOperation stub_method("registerForRemoteNotificationTypes:").with(TEST_NOTIFICATION_TYPE).and_do(^(NSInvocation*) {
//        dispatch_time_t dispatchTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInMilliseconds) * NSEC_PER_MSEC);
//        dispatch_after(dispatchTime, backgroundQueue, ^(void) {
//            [appDelegateProxy application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
//        });
//    });
//}

//void setupRegistrationRequestOperationForFailedAsynchronousRegistration(NSProxy<OmniaPushAppDelegateProxy> *appDelegateProxy, NSError *error, int delayInMilliseconds) {
//    registrationRequestOperation stub_method("registerForRemoteNotificationTypes:").with(TEST_NOTIFICATION_TYPE).and_do(^(NSInvocation*) {
//        dispatch_time_t dispatchTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInMilliseconds) * NSEC_PER_MSEC);
//        dispatch_after(dispatchTime, backgroundQueue, ^(void) {
//            [appDelegateProxy application:application didFailToRegisterForRemoteNotificationsWithError:error];
//        });
//    });
//}

//void setupRegistrationRequestOperationForTimeout(NSProxy<OmniaPushAppDelegateProxy> *appDelegateProxy) {
//    // doesn't invoke callback so the semaphore times out instead
//    registrationRequestOperation stub_method("registerForRemoteNotificationTypes:").with(TEST_NOTIFICATION_TYPE);
//}

OmniaPushAPNSRegistrationRequestOperation* getRegistrationRequestOperation() {
    return registrationRequestOperation;
}

#pragma mark - Front-end singleton helpers

void setRegistrationRequestInSingleton() {
    SEL setupRegistrationRequestSelector = sel_registerName("setupRegistrationRequest:");
    [OmniaPushSDK performSelector:setupRegistrationRequestSelector withObject:registrationRequestOperation];
}

void setApplicationInSingleton() {
    SEL setupApplicationSelector = sel_registerName("setupApplication:");
    [OmniaPushSDK performSelector:setupApplicationSelector withObject:application];
}

void setAppDelegateProxyInSingleton() {
    SEL setupAppDelegateProxySelector = sel_registerName("setupAppDelegateProxy:");
    [OmniaPushSDK performSelector:setupAppDelegateProxySelector withObject:appDelegateProxy];
}

#pragma mark - Operation Queue helpers

OmniaFakeOperationQueue *setupOperationQueue() {
    operationQueue = [[OmniaFakeOperationQueue alloc] init];
    [OmniaPushOperationQueueProvider setOperationQueue:operationQueue];
    return operationQueue;
}

extern OmniaFakeOperationQueue *getOperationQueue() {
    return operationQueue;
}

// TODO - need a method to drain operation queue