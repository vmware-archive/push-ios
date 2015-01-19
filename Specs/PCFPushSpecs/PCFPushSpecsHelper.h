//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PCFPushPersistentStorage;
@class PCFParameters;

OBJC_EXPORT NSString *const TEST_PUSH_API_URL_1;
OBJC_EXPORT NSString *const TEST_VARIANT_UUID_1;
OBJC_EXPORT NSString *const TEST_VARIANT_SECRET_1;
OBJC_EXPORT NSString *const TEST_DEVICE_ALIAS_1;

OBJC_EXPORT NSString *const TEST_VARIANT_UUID;
OBJC_EXPORT NSString *const TEST_VARIANT_SECRET;
OBJC_EXPORT NSString *const TEST_DEVICE_ALIAS;
OBJC_EXPORT NSString *const TEST_DEVICE_MANUFACTURER;
OBJC_EXPORT NSString *const TEST_DEVICE_MODEL;
OBJC_EXPORT NSString *const TEST_OS;
OBJC_EXPORT NSString *const TEST_OS_VERSION;
OBJC_EXPORT NSString *const TEST_REGISTRATION_TOKEN;
OBJC_EXPORT NSString *const TEST_DEVICE_UUID;

@interface PCFPushSpecsHelper : NSObject

@property (nonatomic) id application;
@property (nonatomic) id<UIApplicationDelegate> applicationDelegate;
@property (nonatomic) NSData *apnsDeviceToken;
@property (nonatomic) NSString *backEndDeviceId;
@property (nonatomic) NSString *base64AuthString1;
@property (nonatomic) NSSet *tags1;
@property (nonatomic) NSSet *tags2;
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
- (void) setupApplicationDelegateForSuccessfulRegistration;
- (void) setupApplicationDelegateForFailedRegistrationWithError:(NSError *)error;

// Parameters helpers
- (PCFParameters *)setupParameters;
- (void) setupDefaultPersistedParameters;
- (void) setupDefaultPLIST;
- (void) setupDefaultPLISTWithFile:(NSString*)parameterFilename;

// NSURLConnectionHelpers
- (BOOL) swizzleAsyncRequestWithSelector:(SEL)selector error:(NSError **)error;
- (void)setupSuccessfulAsyncRequestWithBlock:(void(^)(NSURLRequest*))block;
- (void)setupSuccessfulDeleteAsyncRequestAndReturnStatus:(NSInteger)status;

@end;
