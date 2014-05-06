//
//  PCFPushSpecHelper.h
//  PCFPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-31.
//  Copyright (c) 2013 Pivotal. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PCFPushPersistentStorage;
@class PCFParameters;

OBJC_EXPORT NSInteger TEST_NOTIFICATION_TYPES;

OBJC_EXPORT NSString *const TEST_VARIANT_UUID_1;
OBJC_EXPORT NSString *const TEST_RELEASE_SECRET_1;
OBJC_EXPORT NSString *const TEST_DEVICE_ALIAS_1;
OBJC_EXPORT NSString *const TEST_VARIANT_UUID_2;
OBJC_EXPORT NSString *const TEST_RELEASE_SECRET_2;
OBJC_EXPORT NSString *const TEST_DEVICE_ALIAS_2;

@interface PCFPushSpecHelper : NSObject

@property (nonatomic) id application;
@property (nonatomic) id<UIApplicationDelegate> applicationDelegate;
@property (nonatomic) NSData *apnsDeviceToken;
@property (nonatomic) NSData *apnsDeviceToken2;
@property (nonatomic) NSString *backEndDeviceId;
@property (nonatomic) NSString *backEndDeviceId2;
@property (nonatomic) NSString *base64AuthString1;
@property (nonatomic) NSString *base64AuthString2;
@property (nonatomic) PCFParameters *params;


// Spec Helper lifecycle
- (instancetype) init;
- (void) reset;

// Application helpers
- (id) setupApplication;
- (void) setupApplicationForSuccessfulRegistration;
- (void) setupApplicationForSuccessfulRegistrationWithNewApnsDeviceToken:(NSData *)newApnsDeviceToken;
- (void) setupApplicationForFailedRegistrationWithError:(NSError *)error;

// Application Delegate helpers
- (id<UIApplicationDelegate>) setupApplicationDelegate;
- (id<UIApplicationDelegate>) setupMockApplicationDelegateWithRemotePush;
- (id<UIApplicationDelegate>) setupMockApplicationDelegateWithoutRemotePush;
- (void) setupApplicationDelegateForSuccessfulRegistration;
- (void) setupApplicationDelegateForFailedRegistrationWithError:(NSError *)error;
- (void) setupApplicationDelegateToReceiveNotification:(NSDictionary *)userInfo;

// Parameters helpers
- (PCFParameters *)setupParameters;
- (void) changeVariantUUIDInParameters:(NSString *)newVariantUUID;
- (void) changeReleaseSecretInParameters:(NSString *)newReleaseSecret;
- (void) changeDeviceAliasInParameters:(NSString *)newDeviceAlias;
- (void) setupDefaultSavedParameters;

// NSURLConnectionHelpers
- (BOOL) swizzleAsyncRequestWithSelector:(SEL)selector error:(NSError **)error;

@end;
