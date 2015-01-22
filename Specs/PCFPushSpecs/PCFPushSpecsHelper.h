//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PCFPushPersistentStorage;
@class PCFPushParameters;

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

@property NSData *apnsDeviceToken;
@property NSString *backEndDeviceId;
@property NSString *base64AuthString1;
@property NSSet *tags1;
@property NSSet *tags2;
@property PCFPushParameters *params;

// Spec Helper lifecycle
- (instancetype) init;
- (void) reset;

// Parameters helpers
- (PCFPushParameters *)setupParameters;
- (void) setupDefaultPersistedParameters;
- (void) setupDefaultPLIST;
- (void) setupDefaultPLISTWithFile:(NSString*)parameterFilename;

// NSURLConnectionHelpers
- (BOOL) swizzleAsyncRequestWithSelector:(SEL)selector error:(NSError **)error;
- (void)setupAsyncRequestWithBlock:(void(^)(NSURLRequest *request, NSURLResponse **resultResponse, NSData **resultData, NSError **resultError))block;
- (void)setupSuccessfulAsyncRequestWithBlock:(void(^)(NSURLRequest*))block;
- (void)setupSuccessfulDeleteAsyncRequestAndReturnStatus:(NSInteger)status;

@end;
