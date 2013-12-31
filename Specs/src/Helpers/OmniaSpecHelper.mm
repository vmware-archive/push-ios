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
#import "OmniaPushAppDelegateProxyListener.h"

static id<UIApplicationDelegate> appDelegate;
static NSProxy<OmniaPushAppDelegateProxy> *appDelegateProxy;
static id<OmniaPushAppDelegateProxyListener> appDelegateProxyListener;
static id<OmniaPushAPNSRegistrationRequest> registrationRequest;
static NSData *deviceToken;
static UIApplication *application;

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
    appDelegateProxyListener = nil;
    registrationRequest = nil;
}

#pragma mark - App Delegate Helpers

id<UIApplicationDelegate> setupAppDelegate() {
    appDelegate = fake_for(@protocol(UIApplicationDelegate));
    return appDelegate;
}

void setupAppDelegateForSuccessfulRegistration() {
    appDelegate stub_method("application:didRegisterForRemoteNotificationsWithDeviceToken:").with(application, deviceToken);
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

#pragma mark - App Delegate Proxy Listener helpers

id<OmniaPushAppDelegateProxyListener> setupAppDelegateProxyListener() {
    appDelegateProxyListener = fake_for(@protocol(OmniaPushAppDelegateProxyListener));
    return appDelegateProxyListener;
}

void setupAppDelegateProxyListenerForSuccessfulRegistration() {
    appDelegateProxyListener stub_method("application:didRegisterForRemoteNotificationsWithDeviceToken:").with(application, deviceToken);
}

void setupAppDelegateProxyListenerForFailedRegistration(NSError *error) {
    appDelegateProxyListener stub_method("application:didFailToRegisterForRemoteNotificationsWithError:").with(getApplication(), error);
}

id<OmniaPushAppDelegateProxyListener> getAppDelegateProxyListener() {
    return appDelegateProxyListener;
}

#pragma mark - Registration Request helpers

id<OmniaPushAPNSRegistrationRequest> setupRegistrationRequest() {
    registrationRequest = fake_for(@protocol(OmniaPushAPNSRegistrationRequest));
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
