//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * Defines the set of parameters used while registering the device for push notifications or analyitcs.
 * Pass to one of the `register` methods in the `PCFPush` class.
 */
@interface PCFParameters : NSObject

/**
 * Push Parameters
 */
@property BOOL pushAutoRegistrationEnabled;
@property (copy) NSString *pushDeviceAlias;
@property (copy) NSString *pushAPIURL;
@property (copy) NSString *developmentPushVariantUUID;
@property (copy) NSString *developmentPushVariantSecret;
@property (copy) NSString *productionPushVariantUUID;
@property (copy) NSString *productionPushVariantSecret;
@property (copy) NSSet *pushTags;

/**
 * Creates an instance using the values set in the `PCFParameters.plist` file.
 */
+ (PCFParameters *)defaultParameters;

/**
 * Creates an instance using the values found in the specified `.plist` file.
 * @param path The path of the specified file.
 */
+ (PCFParameters *)parametersWithContentsOfFile:(NSString *)path;

/**
 * Creates an instance with empty values.
 */
+ (PCFParameters *)parameters;

/**
 * Validate Push Parameter properties
 */
- (BOOL)arePushParametersValid;

/**
 * The Debug state of the application
 */
- (BOOL)inDebugMode;

/**
 * The variant UUID (resolved using the inProduction flag).
 */
- (NSString *)variantUUID;

/**
 * The variant Secret (resolved using the inProduction flag).
 */
- (NSString *)variantSecret;

@end
