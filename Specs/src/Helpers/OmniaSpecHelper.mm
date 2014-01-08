//
//  OmniaSpecHelper.mm
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-31.
//  Copyright (c) 2013 Omnia. All rights reserved.
//

#import "OmniaSpecHelper.h"
#import "OmniaPushSDK.h"
#import "OmniaPushAPNSRegistrationRequest.h"
#import "OmniaPushAppDelegateProxy.h"
#import "OmniaPushAppDelegateProxyImpl.h"
#import "OmniaPushRegistrationListener.h"
#import "OmniaPushDebug.h"

#define DELAY_TIME_IN_SECONDS 1

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

static id<UIApplicationDelegate> appDelegate;
static NSProxy<OmniaPushAppDelegateProxy> *appDelegateProxy;
static id<OmniaPushRegistrationListener> appDelegateProxyRegistrationListener;
static id<OmniaPushRegistrationListener> sdkInstanceRegistrationListener;
static id<OmniaPushRegistrationListener> sdkRegistrationListener;
static id<OmniaPushAPNSRegistrationRequest> registrationRequest;
static NSData *deviceToken;
static UIApplication *application;
static dispatch_queue_t dispatchQueue = nil;
static dispatch_queue_t backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
static dispatch_time_t DELAY_TIME = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(DELAY_TIME_IN_SECONDS * NSEC_PER_SEC));
static dispatch_semaphore_t sdkInstanceRegistrationSemaphore;
static dispatch_semaphore_t sdkRegistrationSemaphore;

# pragma mark - Spec Helper lifecycle

void setupOmniaSpecHelper() {
    deviceToken = [@"TEST DEVICE TOKEN" dataUsingEncoding:NSUTF8StringEncoding];
    application = [UIApplication sharedApplication];
}

void resetOmniaSpecHelper() {
    deviceToken = nil;
    application = nil;
    appDelegate = nil;
    appDelegateProxy = nil;
    appDelegateProxyRegistrationListener = nil;
    sdkInstanceRegistrationListener = nil;
    sdkRegistrationListener = nil;
    sdkInstanceRegistrationSemaphore = nil;
    sdkRegistrationSemaphore = nil;
    registrationRequest = nil;
    dispatchQueue = nil;
}

#pragma mark - App Delegate Helpers

id<UIApplicationDelegate> setupAppDelegate() {
    appDelegate = fake_for(@protocol(UIApplicationDelegate));
    return appDelegate;
}

void setupAppDelegateForSuccessfulRegistration() {
    appDelegate stub_method("application:didRegisterForRemoteNotificationsWithDeviceToken:").with(application, deviceToken);;
}

void setupAppDelegateForFailedRegistration(NSError *error) {
    appDelegate stub_method("application:didFailToRegisterForRemoteNotificationsWithError:").with(application, error);
}

id<UIApplicationDelegate> getAppDelegate() {
    return appDelegate;
}

#pragma mark - App Delegate Proxy helpers

NSProxy<OmniaPushAppDelegateProxy>* setupAppDelegateProxy() {
    appDelegateProxy = [[OmniaPushAppDelegateProxyImpl alloc] initWithAppDelegate:appDelegate registrationRequest:registrationRequest];
    return appDelegateProxy;
}

NSProxy<OmniaPushAppDelegateProxy>* getAppDelegateProxy() {
    return appDelegateProxy;
}

#pragma mark - App Delegate Proxy Registration Listener helpers

id<OmniaPushRegistrationListener> setupAppDelegateProxyRegistrationListener() {
    appDelegateProxyRegistrationListener = fake_for(@protocol(OmniaPushRegistrationListener));
    return appDelegateProxyRegistrationListener;
}

void setupAppDelegateProxyRegistrationListenerForSuccessfulRegistration() {
    appDelegateProxyRegistrationListener stub_method("application:didRegisterForRemoteNotificationsWithDeviceToken:").with(application, deviceToken);
}

void setupAppDelegateProxyRegistrationListenerForFailedRegistration(NSError *error) {
    appDelegateProxyRegistrationListener stub_method("application:didFailToRegisterForRemoteNotificationsWithError:").with(application, error);
}

id<OmniaPushRegistrationListener> getAppDelegateProxyRegistrationListener() {
    return appDelegateProxyRegistrationListener;
}

#pragma mark - SDK Instance Registration Listener helpers

id<OmniaPushRegistrationListener> setupSDKInstanceRegistrationListener() {
    sdkInstanceRegistrationSemaphore = dispatch_semaphore_create(0);
    sdkInstanceRegistrationListener = fake_for(@protocol(OmniaPushRegistrationListener));
    return sdkInstanceRegistrationListener;
}

void setupSDKInstanceRegistrationListenerForSuccessfulRegistration() {
    sdkInstanceRegistrationListener stub_method("application:didRegisterForRemoteNotificationsWithDeviceToken:").with(application, deviceToken).and_do(^(NSInvocation*) {
        dispatch_semaphore_signal(sdkInstanceRegistrationSemaphore);
    });
}

void setupSDKInstanceRegistrationListenerForFailedRegistration(NSError *error) {
    sdkInstanceRegistrationListener stub_method("application:didFailToRegisterForRemoteNotificationsWithError:").with(application, error).and_do(^(NSInvocation*) {
        dispatch_semaphore_signal(sdkInstanceRegistrationSemaphore);
    });
}

void setupSDKInstanceRegistrationListenerForTimeout() {
    sdkInstanceRegistrationListener stub_method("application:didFailToRegisterForRemoteNotificationsWithError:").with(application, Arguments::any([NSError class])).and_do(^(NSInvocation *inv) {
        // TODO - this code causes an EXC_BAD_ACCESS crash when Cedar cleans up after this method. I think that examining the NSError object inside
        // the invocation makes ARC retain and release it when it really doesn't need to.  I don't know how to prevent this.  Talk to an iOS guru in Toronto.
//        NSError *error = nil;
//        [inv getArgument:&error atIndex:3];
//        error should_not be_nil;
//        error.domain should equal(OmniaPushErrorDomain);
//        error.localizedDescription should contain(@"timed out");
//        error = nil;
        dispatch_semaphore_signal(sdkInstanceRegistrationSemaphore);
    });
}

extern void waitForSDKInstanceRegistrationListenerCallback() {
    dispatch_semaphore_wait(sdkInstanceRegistrationSemaphore, DISPATCH_TIME_FOREVER); // TODO - error if timeout
}

id<OmniaPushRegistrationListener> getSDKInstanceRegistrationListener() {
    return sdkInstanceRegistrationListener;
}

#pragma mark - SDK Registration Listener helpers

id<OmniaPushRegistrationListener> setupSDKRegistrationListener() {
    sdkRegistrationSemaphore = dispatch_semaphore_create(0);
    sdkRegistrationListener = fake_for(@protocol(OmniaPushRegistrationListener));
    return sdkRegistrationListener;
}

void setupSDKRegistrationListenerForSuccessfulRegistration() {
    sdkRegistrationListener stub_method("application:didRegisterForRemoteNotificationsWithDeviceToken:").with(application, deviceToken).and_do(^(NSInvocation*) {
        dispatch_semaphore_signal(sdkRegistrationSemaphore);
    });
}

void setupSDKRegistrationListenerForFailedRegistration(NSError *error) {
    sdkRegistrationListener stub_method("application:didFailToRegisterForRemoteNotificationsWithError:").with(application, error).and_do(^(NSInvocation*) {
        dispatch_semaphore_signal(sdkRegistrationSemaphore);
    });
}

extern void waitForSDKRegistrationListenerCallback() {
    dispatch_semaphore_wait(sdkRegistrationSemaphore, DISPATCH_TIME_FOREVER); // TODO - error if timeout
}

id<OmniaPushRegistrationListener> getSDKRegistrationListener() {
    return sdkRegistrationListener;
}

#pragma mark - Registration Request helpers

id<OmniaPushAPNSRegistrationRequest> setupRegistrationRequest() {
    registrationRequest = fake_for(@protocol(OmniaPushAPNSRegistrationRequest));
    if (!registrationRequest) {
        NSLog(@"Could not allocate fake registration request");
        exit(EXIT_FAILURE);
    }
    return registrationRequest;
}

void setupRegistrationRequestForSuccessfulRegistration(NSProxy<OmniaPushAppDelegateProxy> *appDelegateProxy) {
    registrationRequest stub_method("registerForRemoteNotificationTypes:").with(TEST_NOTIFICATION_TYPE).and_do(^(NSInvocation*) {
        [appDelegateProxy application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
    });
}

void setupRegistrationRequestForFailedRegistration(NSProxy<OmniaPushAppDelegateProxy> *appDelegateProxy, NSError *error) {
    registrationRequest stub_method("registerForRemoteNotificationTypes:").with(TEST_NOTIFICATION_TYPE).and_do(^(NSInvocation*) {
        [appDelegateProxy application:application didFailToRegisterForRemoteNotificationsWithError:error];
    });
}

void setupRegistrationRequestForSuccessfulAsynchronousRegistration(NSProxy<OmniaPushAppDelegateProxy> *appDelegateProxy, int delayInMilliseconds) {
    registrationRequest stub_method("registerForRemoteNotificationTypes:").with(TEST_NOTIFICATION_TYPE).and_do(^(NSInvocation*) {
        dispatch_time_t dispatchTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInMilliseconds) * NSEC_PER_MSEC);
        dispatch_after(dispatchTime, backgroundQueue, ^(void) {
            [appDelegateProxy application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
        });
    });
}

void setupRegistrationRequestForFailedAsynchronousRegistration(NSProxy<OmniaPushAppDelegateProxy> *appDelegateProxy, NSError *error, int delayInMilliseconds) {
    registrationRequest stub_method("registerForRemoteNotificationTypes:").with(TEST_NOTIFICATION_TYPE).and_do(^(NSInvocation*) {
        dispatch_time_t dispatchTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInMilliseconds) * NSEC_PER_MSEC);
        dispatch_after(dispatchTime, backgroundQueue, ^(void) {
            [appDelegateProxy application:application didFailToRegisterForRemoteNotificationsWithError:error];
        });
    });
}

void setupRegistrationRequestForTimeout(NSProxy<OmniaPushAppDelegateProxy> *appDelegateProxy) {
    // doesn't invoke callback so the semaphore times out instead
    registrationRequest stub_method("registerForRemoteNotificationTypes:").with(TEST_NOTIFICATION_TYPE);
}

id<OmniaPushAPNSRegistrationRequest> getRegistrationRequest() {
    return registrationRequest;
}

#pragma mark - Front-end singleton helpers

void setRegistrationRequestInSingleton() {
    SEL setupRegistrationRequestSelector = sel_registerName("setupRegistrationRequest:");
    [OmniaPushSDK performSelector:setupRegistrationRequestSelector withObject:registrationRequest];
}

void setApplicationInSingleton() {
    SEL setupApplicationSelector = sel_registerName("setupApplication:");
    [OmniaPushSDK performSelector:setupApplicationSelector withObject:application];
}

void setAppDelegateProxyInSingleton() {
    SEL setupAppDelegateProxySelector = sel_registerName("setupAppDelegateProxy:");
    [OmniaPushSDK performSelector:setupAppDelegateProxySelector withObject:appDelegateProxy];
}

#pragma mark - Application helpers

UIApplication *getApplication() {
    return application;
}

#pragma mark - Dispatch Queue helpers

dispatch_queue_t setupDispatchQueue() {
    dispatchQueue = dispatch_queue_create("OmniaSpecHelperDispatchQueue", NULL);
    return dispatchQueue;
}

dispatch_queue_t getDispatchQueue() {
    return dispatchQueue;
}