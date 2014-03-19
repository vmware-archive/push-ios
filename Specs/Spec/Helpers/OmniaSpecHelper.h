//
//  OmniaSpecHelper.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-31.
//  Copyright (c) 2013 Pivotal. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OmniaPushAppDelegateProxy;
@class OmniaFakeOperationQueue;
@class OmniaPushPersistentStorage;
@class OmniaPushRegistrationParameters;

OBJC_EXPORT NSInteger TEST_NOTIFICATION_TYPES;

OBJC_EXPORT NSString *const TEST_RELEASE_UUID;
OBJC_EXPORT NSString *const TEST_RELEASE_SECRET;
OBJC_EXPORT NSString *const TEST_DEVICE_ALIAS;
OBJC_EXPORT NSString *const TEST_RELEASE_UUID_2;
OBJC_EXPORT NSString *const TEST_RELEASE_SECRET_2;
OBJC_EXPORT NSString *const TEST_DEVICE_ALIAS_2;

@interface OmniaSpecHelper : NSObject

@property (nonatomic) id application;
@property (nonatomic) id<UIApplicationDelegate> applicationDelegate;
@property (nonatomic) OmniaFakeOperationQueue *workerQueue;
@property (nonatomic) NSData *apnsDeviceToken;
@property (nonatomic) NSData *apnsDeviceToken2;
@property (nonatomic) NSString *backEndDeviceId;
@property (nonatomic) NSString *backEndDeviceId2;
@property (nonatomic) OmniaPushRegistrationParameters *params;

// Spec Helper lifecycle
- (instancetype) init;
- (void) reset;

// Application helpers
- (id) setupApplication;
- (void) setupApplicationForSuccessfulRegistrationWithNotificationTypes:(UIRemoteNotificationType)notificationTypes;
- (void) setupApplicationForSuccessfulRegistrationWithNotificationTypes:(UIRemoteNotificationType)notificationTypes withNewApnsDeviceToken:(NSData*)newApnsDeviceToken;
- (void) setupApplicationForFailedRegistrationWithNotificationTypes:(UIRemoteNotificationType)notificationTypes error:(NSError*)error;

// Application Delegate helpers
- (id<UIApplicationDelegate>) setupApplicationDelegate;
- (void) setupApplicationDelegateForSuccessfulRegistration;
- (void) setupApplicationDelegateForSuccessfulRegistrationWithApnsDeviceToken:(NSData*)apnsDeviceToken;
- (void) setupApplicationDelegateForFailedRegistrationWithError:(NSError*)error;
- (void) setupApplicationDelegateToReceiveNotification:(NSDictionary*)userInfo;

// Operation Queue helpers
- (OmniaFakeOperationQueue*) setupQueues;

// Parameters helpers
- (OmniaPushRegistrationParameters*) setupParametersWithNotificationTypes:(UIRemoteNotificationType)notificationTypes;
- (void) changeReleaseUuidInParameters:(NSString*)newReleaseUuid;
- (void) changeReleaseSecretInParameters:(NSString*)newReleaseSecret;
- (void) changeDeviceAliasInParameters:(NSString*)newDeviceAlias;

// NSURLConnectionHelpers
- (BOOL) swizzleAsyncRequestWithSelector:(SEL)selector error:(NSError **)error;

@end;
