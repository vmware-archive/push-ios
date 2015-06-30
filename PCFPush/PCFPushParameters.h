//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

extern void pcfPushResetOnceToken(); // For unit tests

extern BOOL pcfPushIsAPNSSandbox();

/**
 * Defines the set of parameters used while registering the device for push notifications or analyitcs.
 * Pass to one of the `register` methods in the `PCFPush` class.
 */
@interface PCFPushParameters : NSObject

/**
 * Push Parameters
 */
@property (copy) NSString *pushDeviceAlias;
@property (copy) NSString *pushAPIURL;
@property (copy) NSString *developmentPushVariantUUID;
@property (copy) NSString *developmentPushVariantSecret;
@property (copy) NSString *productionPushVariantUUID;
@property (copy) NSString *productionPushVariantSecret;
@property (copy) NSArray *pinnedSslCertificateNames;
@property (assign) BOOL trustAllSslCertificates;
@property (copy) NSSet *pushTags;
@property BOOL areGeofencesEnabled;

/**
 * Creates an instance using the values set in the `Pivotal.plist` file.
 */
+ (PCFPushParameters *)defaultParameters;

/**
 * Creates an instance using the values found in the specified `.plist` file.
 * @param path The path of the specified file.
 */
+ (PCFPushParameters *)parametersWithContentsOfFile:(NSString *)path;

/**
 * Creates an instance with empty values.
 */
+ (PCFPushParameters *)parameters;

/**
 * Validate Push Parameter properties
 */
- (BOOL)arePushParametersValid;

/**
 * The variant UUID (resolved using the inProduction flag).
 */
- (NSString *)variantUUID;

/**
 * The variant Secret (resolved using the inProduction flag).
 */
- (NSString *)variantSecret;

@end
