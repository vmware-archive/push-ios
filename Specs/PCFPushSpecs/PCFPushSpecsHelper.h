//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PCFPushParameters;
@class PCFPushAnalyticsStorage;
@class PCFPushPersistentStorage;

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

OBJC_EXPORT const int64_t TEST_GEOFENCE_ID;
OBJC_EXPORT NSString *const TEST_GEOFENCE_LOCATION_NAME;
OBJC_EXPORT const double TEST_GEOFENCE_LATITUDE;
OBJC_EXPORT const double TEST_GEOFENCE_LONGITUDE;
OBJC_EXPORT const double TEST_GEOFENCE_RADIUS;

@interface PCFPushSpecsHelper : NSObject

@property NSData *apnsDeviceToken;
@property NSString *backEndDeviceId;
@property NSString *base64AuthString1;
@property NSSet *tags1;
@property NSSet *tags2;
@property NSDate *testGeofenceDate;
@property PCFPushParameters *params;
@property PCFPushAnalyticsStorage *analyticsStorage;

// Spec Helper lifecycle
- (instancetype) init;
- (void) reset;

// Parameters helpers
- (PCFPushParameters *)setupParameters;
- (PCFPushParameters *)setupParametersWithGeofencesEnabled:(BOOL)geofencesEnabled;
- (void) setupDefaultPersistedParameters;
- (void) setupDefaultPLIST;
- (void) setupDefaultPLISTWithFile:(NSString*)parameterFilename;

// NSURLConnectionHelpers
- (void)setupAsyncRequestWithBlock:(void(^)(NSURLRequest *request, NSURLResponse **resultResponse, NSData **resultData, NSError **resultError))block;
- (void)setupSuccessfulAsyncRegistrationRequest;
- (void)setupSuccessfulAsyncRegistrationRequestWithBlock:(void(^)(NSURLRequest*))block;
- (void)setupSuccessfulDeleteAsyncRequestAndReturnStatus:(NSInteger)status;

// Geofence update helpers
- (void)setupGeofencesForSuccessfulUpdateWithLastModifiedTime:(int64_t)lastModifiedTime;
- (void)setupGeofencesForSuccessfulUpdateWithLastModifiedTime:(int64_t)lastModifiedTime withBlock:(void(^)(NSArray *))block;
- (void)setupGeofencesForFailedUpdate;
- (void)setupGeofencesForFailedUpdateWithBlock:(void(^)(NSArray *))block;
- (void)setupClearGeofencesForSuccess;

// Analytics helpers
- (void)setupAnalyticsStorage;

@end;
