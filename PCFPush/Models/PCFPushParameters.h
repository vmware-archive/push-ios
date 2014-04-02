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

@property (readonly) UIRemoteNotificationType remoteNotificationTypes;
@property (readonly) NSString *variantUUID;
@property (readonly) NSString *releaseSecret;
@property (readonly) NSString *deviceAlias;

/**
 * Initialize the parameters object.
 *
 * @param types Defines the set of notifications that iOS will display when
 *              push notifications are received while your application is
 *              not running.
 *
 * @param releaseUuid   The "variant_uuid", as defined by PCF Push Services for your release.
 *                      May not be `nil` or empty.
 *
 * @param releaseSecret The "release secret", as defined by PCF Push Services for your release.
 *                      May not be `nil` or empty.
 *
 * @param deviceAlias   A developer-defined "device alias" which can be used to designate this device, or class.
 *                      of devices, in push or notification campaigns. May not be `nil`. May be empty.
 *
 */
+ (instancetype)parametersWithNotificationTypes:(UIRemoteNotificationType)types
                                    variantUUID:(NSString *)variantUUID
                                  releaseSecret:(NSString *)releaseSecret
                                    deviceAlias:(NSString *)deviceAlias;

@end
