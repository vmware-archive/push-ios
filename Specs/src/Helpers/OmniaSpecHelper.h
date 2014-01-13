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

@class OmniaPushAppDelegateProxyImpl;
@class OmniaPushAPNSRegistrationRequestOperation;
@class OmniaFakeOperationQueue;

@interface OmniaSpecHelper : NSObject

@property (nonatomic) id application;
@property (nonatomic) id<UIApplicationDelegate> applicationDelegate;
@property (nonatomic) OmniaFakeOperationQueue *operationQueue;
@property (nonatomic) OmniaPushAPNSRegistrationRequestOperation *registrationRequestOperation;
@property (nonatomic) OmniaPushAppDelegateProxyImpl *applicationDelegateProxy;

// Spec Helper lifecycle
- (instancetype) init;
- (void) reset;

// Front-end singleton helpers
//- (void) setRegistrationRequestInSingleton;
//- (void) setApplicationInSingleton;
//XXextern void setAppDelegateProxyInSingleton();

// Application helpers
- (id) setupApplication;
- (void) setupApplicationForSuccessfulRegistrationWithNotificationTypes:(UIRemoteNotificationType)notificationTypes;
- (void) setupApplicationForFailedRegistrationWithNotificationTypes:(UIRemoteNotificationType)notificationTypes error:(NSError*)error;

// Application Delegate helpers
- (id<UIApplicationDelegate>) setupApplicationDelegate;
- (void) setupApplicationDelegateForSuccessfulRegistration;
- (void) setupApplicationDelegateForFailedRegistrationWithError:(NSError*)error;

// Registration Request Operation helpers
- (OmniaPushAPNSRegistrationRequestOperation*) setupRegistrationRequestOperationWithNotificationTypes:(UIRemoteNotificationType)notificationTypes;
//- (void) setupRegistrationRequestOperationForSuccessfulRegistrationWithApplicationDelegateProxy:(NSProxy<OmniaPushAppDelegateProxy>*)applicationDelegateProxy;
//- (void) setupRegistrationRequestOperationForFailedRegistrationWithApplicationDelegateProxy:(NSProxy<OmniaPushAppDelegateProxy>*)appDelegateProxy error:(NSError*)error;
//- (void) setupRegistrationRequestOperationForSuccessfulAsynchronousRegistrationWithApplicationDelegateProxy:(NSProxy<OmniaPushAppDelegateProxy>*)appDelegateProxy delayInMilliseconds:(int)delayInMilliseconds;
//- (void) setupRegistrationRequestOperationForFailedAsynchronousRegistrationWithApplicationDelegateProxy:(NSProxy<OmniaPushAppDelegateProxy>*)appDelegateProxy error:(NSError*)error delayInMilliseconds:(int)delayInMilliseconds;
//- (void) setupRegistrationRequestOperationForTimeoutWithApplicationDelegateProxy:(NSProxy<OmniaPushAppDelegateProxy>*)appDelegateProxy;

// Operation Queue helpers
- (OmniaFakeOperationQueue*) setupOperationQueue;

@end