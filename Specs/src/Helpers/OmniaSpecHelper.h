//
//  SpecHelper.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-31.
//  Copyright (c) 2013 Omnia. All rights reserved.
//

#import <UIKit/UIKit.h>

#define TEST_NOTIFICATION_TYPE UIRemoteNotificationTypeBadge

@protocol OmniaPushAPNSRegistrationRequest;
@protocol OmniaPushAppDelegateProxy;
@protocol OmniaPushRegistrationListener;

// Spec Helper lifecycle
extern void setupOmniaSpecHelper();
extern void resetOmniaSpecHelper();

// Front-end singleton helpers
extern void setRegistrationRequestInSingleton();
extern void setApplicationInSingleton();
extern void setAppDelegateProxyInSingleton();

// Application helpers
extern UIApplication *getApplication();

// App Delegate helpers
extern id<UIApplicationDelegate> setupAppDelegate();
extern void setupAppDelegateForSuccessfulRegistration();
extern void setupAppDelegateForFailedRegistration(NSError *error);
extern id<UIApplicationDelegate> getAppDelegate();

// App Delegate Proxy helpers
extern NSProxy<OmniaPushAppDelegateProxy>* setupAppDelegateProxy();
extern NSProxy<OmniaPushAppDelegateProxy>* getAppDelegateProxy();

// App Delegate Proxy Registration Listener helpers
extern id<OmniaPushRegistrationListener> setupAppDelegateProxyRegistrationListener();
extern void setupAppDelegateProxyRegistrationListenerForSuccessfulRegistration();
extern void setupAppDelegateProxyRegistrationListenerForFailedRegistration(NSError *error);
extern id<OmniaPushRegistrationListener> getAppDelegateProxyRegistrationListener();

// SDK Instance Registration Listener helpers
extern id<OmniaPushRegistrationListener> setupSDKInstanceRegistrationListener();
extern void setupSDKInstanceRegistrationListenerForSuccessfulRegistration();
extern void setupSDKInstanceRegistrationListenerForFailedRegistration(NSError *error);
extern void waitForSDKInstanceRegistrationListenerCallback();
extern id<OmniaPushRegistrationListener> getSDKInstanceRegistrationListener();

// SDK Registration Listener helpers
extern id<OmniaPushRegistrationListener> setupSDKRegistrationListener();
extern void setupSDKRegistrationListenerForSuccessfulRegistration();
extern void setupSDKRegistrationListenerForFailedRegistration(NSError *error);
extern void waitForSDKRegistrationListenerCallback();
extern id<OmniaPushRegistrationListener> getSDKRegistrationListener();

// Registration Request helpers
extern id<OmniaPushAPNSRegistrationRequest> setupRegistrationRequest();
extern void setupRegistrationRequestForSuccessfulRegistration(NSProxy<OmniaPushAppDelegateProxy> *appDelegateProxy);
extern void setupRegistrationRequestForFailedRegistration(NSProxy<OmniaPushAppDelegateProxy> *appDelegateProxy, NSError *error);
extern void setupRegistrationRequestForSuccessfulAsynchronousRegistration(NSProxy<OmniaPushAppDelegateProxy> *appDelegateProxy);
extern void setupRegistrationRequestForFailedAsynchronousRegistration(NSProxy<OmniaPushAppDelegateProxy> *appDelegateProxy, NSError *error);
extern void setupRegistrationRequestForTimeout(NSProxy<OmniaPushAppDelegateProxy> *appDelegateProxy);
extern id<OmniaPushAPNSRegistrationRequest> getRegistrationRequest();

// Dispatch Queue helpers
extern dispatch_queue_t setupDispatchQueue();
extern dispatch_queue_t getDispatchQueue();
