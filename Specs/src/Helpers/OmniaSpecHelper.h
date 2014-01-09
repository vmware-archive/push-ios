//
//  SpecHelper.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-31.
//  Copyright (c) 2013 Omnia. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OmniaPushAppDelegateProxy;
@protocol OmniaPushRegistrationListener;

@class OmniaPushAPNSRegistrationRequestOperation;
@class OmniaFakeOperationQueue;

// Spec Helper lifecycle
extern void setupOmniaSpecHelper();
extern void resetOmniaSpecHelper();

// Front-end singleton helpers
extern void setRegistrationRequestInSingleton();
extern void setApplicationInSingleton();
//XXextern void setAppDelegateProxyInSingleton();

// Application helpers
extern UIApplication *setupApplication();
extern void setupApplicationForSuccessfulRegistration(UIRemoteNotificationType notificationTypes);
extern void setupApplicationForFailedRegistration(UIRemoteNotificationType notificationTypes, NSError *error);
extern UIApplication *getApplication();

// Application Delegate helpers
extern id<UIApplicationDelegate> setupApplicationDelegate();
extern void setupApplicationDelegateForSuccessfulRegistration();
extern void setupApplicationDelegateForFailedRegistration(NSError *error);
extern id<UIApplicationDelegate> getApplicationDelegate();

// App Delegate Proxy helpers
extern NSProxy<OmniaPushAppDelegateProxy>* setupAppDelegateProxy();
extern NSProxy<OmniaPushAppDelegateProxy>* getAppDelegateProxy();
//
//// App Delegate Proxy Registration Listener helpers
//extern id<OmniaPushRegistrationListener> setupAppDelegateProxyRegistrationListener();
//extern void setupAppDelegateProxyRegistrationListenerForSuccessfulRegistration();
//extern void setupAppDelegateProxyRegistrationListenerForFailedRegistration(NSError *error);
//extern id<OmniaPushRegistrationListener> getAppDelegateProxyRegistrationListener();
//
//// SDK Instance Registration Listener helpers
//extern id<OmniaPushRegistrationListener> setupSDKInstanceRegistrationListener();
//extern void setupSDKInstanceRegistrationListenerForSuccessfulRegistration();
//extern void setupSDKInstanceRegistrationListenerForFailedRegistration(NSError *error);
//extern void setupSDKInstanceRegistrationListenerForTimeout();
//extern id<OmniaPushRegistrationListener> getSDKInstanceRegistrationListener();
//
//// SDK Registration Listener helpers
//extern id<OmniaPushRegistrationListener> setupSDKRegistrationListener();
//extern void setupSDKRegistrationListenerForSuccessfulRegistration();
//extern void setupSDKRegistrationListenerForFailedRegistration(NSError *error);
//extern id<OmniaPushRegistrationListener> getSDKRegistrationListener();

// Registration Request Operation helpers
extern OmniaPushAPNSRegistrationRequestOperation* setupRegistrationRequestOperation(UIRemoteNotificationType notificationTypes);
extern void setupRegistrationRequestOperationForSuccessfulRegistration(NSProxy<OmniaPushAppDelegateProxy> *appDelegateProxy);
extern void setupRegistrationRequestOperationForFailedRegistration(NSProxy<OmniaPushAppDelegateProxy> *appDelegateProxy, NSError *error);
extern void setupRegistrationRequestOperationForSuccessfulAsynchronousRegistration(NSProxy<OmniaPushAppDelegateProxy> *appDelegateProxy, int delayInMilliseconds);
extern void setupRegistrationRequestOperationForFailedAsynchronousRegistration(NSProxy<OmniaPushAppDelegateProxy> *appDelegateProxy, NSError *error, int delayInMilliseconds);
extern void setupRegistrationRequestOperationForTimeout(NSProxy<OmniaPushAppDelegateProxy> *appDelegateProxy);
extern OmniaPushAPNSRegistrationRequestOperation* getRegistrationRequestOperation();

#pragma mark - Operation Queue helpers

extern OmniaFakeOperationQueue *setupOperationQueue();
extern OmniaFakeOperationQueue *getOperationQueue();
