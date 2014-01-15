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
@class OmniaPushFakeApplicationDelegateSwitcher;

@interface OmniaSpecHelper : NSObject

@property (nonatomic) id application;
@property (nonatomic) id<UIApplicationDelegate> applicationDelegate;
@property (nonatomic) OmniaFakeOperationQueue *operationQueue;
@property (nonatomic) OmniaPushAPNSRegistrationRequestOperation *registrationRequestOperation;
@property (nonatomic) OmniaPushAppDelegateProxyImpl *applicationDelegateProxy;
@property (nonatomic) OmniaPushFakeApplicationDelegateSwitcher *applicationDelegateSwitcher;
@property (nonatomic) NSData *deviceToken;

// Spec Helper lifecycle
- (instancetype) init;
- (void) reset;

// Front-end singleton helpers
- (void) resetSingleton;
- (void) setApplicationInSingleton;

// Application helpers
- (id) setupApplication;
- (void) setupApplicationForSuccessfulRegistrationWithNotificationTypes:(UIRemoteNotificationType)notificationTypes;
- (void) setupApplicationForFailedRegistrationWithNotificationTypes:(UIRemoteNotificationType)notificationTypes error:(NSError*)error;

// Application Delegate helpers
- (id<UIApplicationDelegate>) currentApplicationDelegate;
- (id<UIApplicationDelegate>) setupApplicationDelegate;
- (void) setupApplicationDelegateForSuccessfulRegistration;
- (void) setupApplicationDelegateForFailedRegistrationWithError:(NSError*)error;

// Registration Request Operation helpers
- (OmniaPushAPNSRegistrationRequestOperation*) setupRegistrationRequestOperationWithNotificationTypes:(UIRemoteNotificationType)notificationTypes;

// Operation Queue helpers
- (OmniaFakeOperationQueue*) setupOperationQueue;

@end