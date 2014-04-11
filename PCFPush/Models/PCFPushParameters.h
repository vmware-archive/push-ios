//
//  PCFPushRegistrationParameters.h
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
@interface PCFPushParameters : NSObject

@property (assign) UIRemoteNotificationType remoteNotificationTypes;
@property (copy) NSString *deviceAlias;
@property (copy) NSString *deviceAPIURL;

@property (copy) NSString *developmentVariantUUID;
@property (copy) NSString *developmentReleaseSecret;

@property (copy) NSString *productionVariantUUID;
@property (copy) NSString *productionReleaseSecret;

/**
 * Creates an instance using the values set in the `PCFPushParameters.plist` file.
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
 * Validate the parameters
 */
- (BOOL)validate;

@end
