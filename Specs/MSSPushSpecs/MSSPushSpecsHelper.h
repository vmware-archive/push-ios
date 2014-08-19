//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MSSPushPersistentStorage;
@class MSSParameters;

OBJC_EXPORT NSInteger TEST_NOTIFICATION_TYPES;

OBJC_EXPORT NSString *const TEST_VARIANT_UUID_1;
OBJC_EXPORT NSString *const TEST_VARIANT_SECRET_1;
OBJC_EXPORT NSString *const TEST_DEVICE_ALIAS_1;
OBJC_EXPORT NSString *const TEST_VARIANT_UUID_2;
OBJC_EXPORT NSString *const TEST_VARIANT_SECRET_2;
OBJC_EXPORT NSString *const TEST_DEVICE_ALIAS_2;
//OBJC_EXPORT NSArray *TEST_TAGS;
//OBJC_EXPORT NSArray *TEST_SUBSCRIBE_TAGS;
//OBJC_EXPORT NSArray *TEST_UNSUBSCRIBE_TAGS;

@interface MSSPushSpecsHelper : NSObject

@property (nonatomic) id application;
@property (nonatomic) id<UIApplicationDelegate> applicationDelegate;
@property (nonatomic) NSData *apnsDeviceToken;
@property (nonatomic) NSData *apnsDeviceToken2;
@property (nonatomic) NSString *backEndDeviceId;
@property (nonatomic) NSString *backEndDeviceId2;
@property (nonatomic) NSString *base64AuthString1;
@property (nonatomic) NSString *base64AuthString2;
@property (nonatomic) MSSParameters *params;


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
- (MSSParameters *)setupParameters;
- (void) changeVariantUUIDInParameters:(NSString *)newVariantUUID;
- (void) changeVariantSecretInParameters:(NSString *)newVariantSecret;
- (void) changeDeviceAliasInParameters:(NSString *)newDeviceAlias;
- (void) setupDefaultSavedParameters;

// NSURLConnectionHelpers
- (BOOL) swizzleAsyncRequestWithSelector:(SEL)selector error:(NSError **)error;

@end;
