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
@protocol OmniaPushAppDelegateProxyListener;

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

// App Delegate Proxy Listener helpers
extern id<OmniaPushAppDelegateProxyListener> setupAppDelegateProxyListener();
extern void setupAppDelegateProxyListenerForSuccessfulRegistration();
extern void setupAppDelegateProxyListenerForFailedRegistration(NSError *error);
extern id<OmniaPushAppDelegateProxyListener> getAppDelegateProxyListener();

// Registration Request helpers
extern id<OmniaPushAPNSRegistrationRequest> setupRegistrationRequest();
extern void setupRegistrationRequestForSuccessfulRegistration(NSProxy<OmniaPushAppDelegateProxy> *appDelegateProxy);
extern void setupRegistrationRequestForFailedRegistration(NSProxy<OmniaPushAppDelegateProxy> *appDelegateProxy, NSError *error);
extern id<OmniaPushAPNSRegistrationRequest> getRegistrationRequest();
