//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MSSParameters;

//TODO: Complete documentation

/**
 * Primary entry point for the CF Push Client SDK library.
 *
 * Usage: see `README.md`
 *
 */
@interface MSSPush : NSObject

/**
 * Sets the registration parameters of the application for receiving push notifications. If some of the
 * registration parameters are different then the last successful registration then the device will be re-registered with the new parameters.
 *
 * @param parameters Provides the parameters required for registration.  May not be `nil`.
 *
 */
+ (void)setRegistrationParameters:(MSSParameters *)parameters;

+ (void)setRemoteNotificationTypes:(UIRemoteNotificationType)notificationTypes;

/**
 * @param success block that will be executed if registration finishes successfully. This callback will
 *                be called on the main queue.  May be `nil`.
 *
 * @param failure block that will be executed if registration fails. This callback will be called on the main
 *                queue.  May be `nil`.
 */
+ (void)setCompletionBlockWithSuccess:(void (^)(void))success
                              failure:(void (^)(NSError *error))failure;

/**
 * Manual call to register device for push notifications
 *
 */
+ (void)registerForPushNotifications;


/**
 * Asynchronously unregisters the device and application from receiving push notifications.  If the application
 * is not yet registered, then this call will do nothing.
 *
 * @param success block that will be executed if unregistration is successful. This callback will be called on 
 *                the main queue. May be 'nil'.
 *
 * @param failure block that will be executed if unregistration fails. This callback will be called on the main
 *                queue. May be 'nil'.
 */
+ (void)unregisterWithPushServerSuccess:(void (^)(void))success
                                failure:(void (^)(NSError *error))failure;

@end
