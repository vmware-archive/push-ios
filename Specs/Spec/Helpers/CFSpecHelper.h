//
//  CFSpecHelper.h
//  CFPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-31.
//  Copyright (c) 2013 Pivotal. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CFPushPersistentStorage;
@class CFPushParameters;

OBJC_EXPORT NSInteger TEST_NOTIFICATION_TYPES;

OBJC_EXPORT NSString *const TEST_RELEASE_UUID_1;
OBJC_EXPORT NSString *const TEST_RELEASE_SECRET_1;
OBJC_EXPORT NSString *const TEST_DEVICE_ALIAS_1;
OBJC_EXPORT NSString *const TEST_RELEASE_UUID_2;
OBJC_EXPORT NSString *const TEST_RELEASE_SECRET_2;
OBJC_EXPORT NSString *const TEST_DEVICE_ALIAS_2;

@interface CFSpecHelper : NSObject

@property (nonatomic) id application;
@property (nonatomic) id<UIApplicationDelegate> applicationDelegate;
@property (nonatomic) NSData *apnsDeviceToken;
@property (nonatomic) NSData *apnsDeviceToken2;
@property (nonatomic) NSString *backEndDeviceId;
@property (nonatomic) NSString *backEndDeviceId2;
@property (nonatomic) CFPushParameters *params;

// Spec Helper lifecycle
- (instancetype) init;
- (void) reset;

// Application helpers
- (id) setupApplication;
- (void) setupApplicationForSuccessfulRegistrationWithNotificationTypes:(UIRemoteNotificationType)notificationTypes;
- (void) setupApplicationForSuccessfulRegistrationWithNotificationTypes:(UIRemoteNotificationType)notificationTypes withNewApnsDeviceToken:(NSData *)newApnsDeviceToken;
- (void) setupApplicationForFailedRegistrationWithNotificationTypes:(UIRemoteNotificationType)notificationTypes error:(NSError *)error;

// Application Delegate helpers
- (id<UIApplicationDelegate>) setupApplicationDelegate;
- (void) setupApplicationDelegateForSuccessfulRegistration;
- (void) setupApplicationDelegateForSuccessfulRegistrationWithApnsDeviceToken:(NSData *)apnsDeviceToken;
- (void) setupApplicationDelegateForFailedRegistrationWithError:(NSError *)error;
- (void) setupApplicationDelegateToReceiveNotification:(NSDictionary *)userInfo;

// Parameters helpers
- (CFPushParameters*) setupParametersWithNotificationTypes:(UIRemoteNotificationType)notificationTypes;
- (void) changeReleaseUuidInParameters:(NSString *)newReleaseUuid;
- (void) changeReleaseSecretInParameters:(NSString *)newReleaseSecret;
- (void) changeDeviceAliasInParameters:(NSString *)newDeviceAlias;
- (void) setupDefaultSavedParameters;

// NSURLConnectionHelpers
- (BOOL) swizzleAsyncRequestWithSelector:(SEL)selector error:(NSError **)error;

@end;
