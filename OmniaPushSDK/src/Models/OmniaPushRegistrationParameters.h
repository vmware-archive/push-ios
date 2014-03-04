//
//  OmniaPushRegistrationParameters.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-21.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * Defines the set of parameters used while registering the device for push notifications.
 * Pass to one of the `register` methods in the `OmniaPushSDK` class.
 */
@interface OmniaPushRegistrationParameters : NSObject

@property (nonatomic, readonly) UIRemoteNotificationType remoteNotificationTypes;
@property (nonatomic, readonly) NSString *releaseUuid;
@property (nonatomic, readonly) NSString *releaseSecret;
@property (nonatomic, readonly) NSString *deviceAlias;

/**
 * Initialize the parameters object.
 *
 * @param remoteNotificationTypes Defines the set of notifications that iOS will display when
 *                                push notifications are received while your application is
 *                                not running.
 *
 * @param releaseUuid   The "release_uuid", as defined by Omnia Push Services for your release.
 *                      May not be `nil` or empty.
 *
 * @param releaseSecret The "release secret", as defined by Omnia Push Services for your release.
 *                      May not be `nil` or empty.
 *
 * @param deviceAlias   A developer-defined "device alias" which can be used to designate this device, or class.
 *                      of devices, in push or notification campaigns. May not be `nil`. May be empty.
 */
+ (instancetype) parametersForNotificationTypes:(UIRemoteNotificationType)remoteNotificationTypes
                                    releaseUuid:(NSString *)releaseUuid
                                  releaseSecret:(NSString *)releaseSecret
                                    deviceAlias:(NSString *)deviceAlias;

@end
