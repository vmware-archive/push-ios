//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * Defines the set of parameters used while registering the device for push notifications or analyitcs.
 * Pass to one of the `register` methods in the `MSSPushSDK` class.
 */
@interface MSSParameters : NSObject

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
@property (copy) NSArray *tags;

/**
 * Creates an instance using the values set in the `MSSParameters.plist` file.
 */
+ (MSSParameters *)defaultParameters;

/**
 * Creates an instance using the values found in the specified `.plist` file.
 * @param path The path of the specified file.
 */
+ (MSSParameters *)parametersWithContentsOfFile:(NSString *)path;

/**
 * Creates an instance with empty values.
 */
+ (MSSParameters *)parameters;

/**
 * Validate Push Parameter properties
 */
- (BOOL)pushParametersValid;

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
