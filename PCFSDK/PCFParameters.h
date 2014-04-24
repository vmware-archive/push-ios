//
//  PCFParameters.h
//  PCFPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-21.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * Defines the set of parameters used while registering the device for push notifications.
 * Pass to one of the `register` methods in the `PCFPushSDK` class.
 */
@interface PCFParameters : NSObject

@property (copy) NSString *deviceAlias;
@property (copy) NSString *pushAPIURL;
@property (copy) NSString *analyticsAPIURL;
@property BOOL autoRegistrationEnabled;

@property (copy) NSString *developmentVariantUUID;
@property (copy) NSString *developmentReleaseSecret;

@property (copy) NSString *productionVariantUUID;
@property (copy) NSString *productionReleaseSecret;

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
 * Validate all properties are populated
 */
- (BOOL)isValid;

/**
 * The production state of the application
 */
- (BOOL)inProduction;

/**
 * The current variant UUID (resolved using the inProduction flag).
 */
- (NSString *)variantUUID;

/**
 * The current release Secret (resolved using the inProduction flag).
 */
- (NSString *)releaseSecret;

@end
