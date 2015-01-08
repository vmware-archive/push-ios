//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PCFParameters;

/**
 * Primary entry point for the CF Push Client SDK library.
 *
 * Usage: see `README.md`
 */
@interface PCFPush : NSObject

/**
 * Sets the registration parameters of the application for receiving push notifications. If some of the
 * registration parameters are different then the last successful registration then the device will be re-registered
 * with the new parameters.
 *
 * @param parameters Provides the parameters required for registration.  May not be `nil`.
 */

+ (void) setRegistrationParameters:(PCFParameters *)parameters;

/**
 * Sets the type of alerts the user can receive when they receive a remote notification.
 * Applies to iOS 7.1 and earler.
 *
 * The notification types default to (UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound).
 *
 * If you are using automatic registration then you may only user the default notification types above.
 *
 * If you want to use a subset of the above default notification types then you must use manual registration.
 *
 * On iOS 8.0+ you should call "- (void) registerUserNotificationSettings:" on [UIApplication sharedApplication] instead
 * in order to request the type of alerts that the user can receive when they receive remote and/or local notifications.
 *
 * Note that on iOS 8.0+ you will still need to call [PCFPush registerforPushNotifications] in order to register
 * for remote notifications and activate the Pivotal CF Mobile Services push services SDK.
 *
 * @param notificationTypes the type of alert that the user can receive when they receive a remote notification.
 */

+ (void) setRemoteNotificationTypes:(UIRemoteNotificationType)notificationTypes;

/**
 * @param success block that will be executed if registration finishes successfully. This callback will
 *                be called on the main queue.  May be `nil`.
 *
 * @param failure block that will be executed if registration fails. This callback will be called on the main
 *                queue.  May be `nil`.
 */

+ (void) setCompletionBlockWithSuccess:(void (^)(void))success
                               failure:(void (^)(NSError *error))failure;

/**
 * Manually registers device for push notifications.
 *
 * Before calling this method, you should call [PCFPush setRegistrationParameters] to provide the registration
 * parameters and call [PCFPush setRemoteNotificationTypes] if you want to provide a different subset of the
 * notification types.  If you want a callback indicating success or failure of the registration operation then
 * you should also call [PCFPush setCompletionBlockWithSuccess:failure].
 *
 * If you want to do automatic registration, then instead provide a PLIST file called "PCFParameters.plist" with
 * the following registration parameters:
 * 
 *   pushAutoRegistrationEnabled
 *   pushAPIURL
 *   pushDeviceAlias
 *   productionPushVariantSecret
 *   productionPushVariantUUID
 *   developmentPushVariantSecret
 *   developmentPushVariantUUID
 */

+ (void) registerForPushNotifications;

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

+ (void) unregisterWithPushServerSuccess:(void (^)(void))success
                                 failure:(void (^)(NSError *error))failure;

@end
