//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * Primary entry point for the CF Push Client SDK library.
 *
 * Usage: see `README.md`
 */
@interface PCFPush : NSObject

/**
 * Registers device for push notifications.
 *
 * Before calling this method, you should call [PCFPush setRegistrationParameters] to provide the registration
 * parameters and call [PCFPush setRemoteNotificationTypes] if you want to provide a different subset of the
 * notification types.  If you want a callback indicating success or failure of the registration operation then
 * you should also call [PCFPush setCompletionBlockWithSuccess:failure].
 *
 * IMPORTANT: You MUST also implement the -application:didRegisterForRemoteNotificationWithDeviceToken: and
 * -application:didFailToRegisterForRemoteNotificationsWithError: methods in your UIApplicationDelegate class
 * and call [PCFPush APNSRegistrationSucceededWithDeviceToken:] and [PCFPush APNSRegistrationFailedWithError]
 * methods respectively in order to successfully complete integration with this library.  If you do not
 * then you will NOT be able to successfully register for remote notifications with Pivotal CF Push.
 *
 * To provide parameters, you must provide a PLIST file called "Pivotal.plist" with the following registration
 * parameters:
 *
 *    pivotal.push.serviceUrl
 *    pivotal.push.variantSecret.production
 *    pivotal.push.variantUuid.production
 *    pivotal.push.variantSecret.development
 *    pivotal.push.variantUuid.development
 *
 * None of the above values may be `nil`.  None of the above values may be empty.
 */
+ (void) registerForPushNotifications;

/**
 * IMPORTANT!  You must call this method from your -application:didRegisterForRemoteNotificationWithDeviceToken:
 * method in your UIApplicationDelegate in order to successfully integrate with Pivotal CF Push.
 *
 * example:
 *
 * - (void) application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
 * {
 *     NSLog(@"APNS registration succeeded!");
 *     [PCFPush APNSRegistrationSucceededWithDeviceToken:deviceToken]; // Continue registration with PCF Push
 * }
 */
+ (void)APNSRegistrationSucceededWithDeviceToken:(NSData *)deviceToken;

/**
 * IMPORTANT!  You must call this method from your -application:didFailToRegisterForRemoteNotificationsWithError:
 * method in your UIApplicationDelegate in order to successfully integrate with Pivotal CF Push.
 *
 * example:
 *
 * - (void) application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
 * {
 *     NSLog(@"APNS registration failed!");
 *     [PCFPush APNSRegistrationFailedWithError:error]; // Continue registration with PCF Push
 * }
 */
+ (void)APNSRegistrationFailedWithError:(NSError *)error;

/**
 * Sets the type of alerts the user can receive when they receive a remote notification.
 * Applies to iOS 7.1 and earlier.
 *
 * The notification types default to (UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound).
 *
 * If you want to use a subset of the above default notification types then you must use manual registration.
 *
 * On iOS 8.0+ you should call "- (void) registerUserNotificationSettings:" on [UIApplication sharedApplication] instead
 * in order to request the type of alerts that the user can receive when they receive remote and/or local notifications.
 *
 * Note that on iOS 8.0+ you will still need to call [PCFPush registerForPushNotifications] in order to register
 * for remote notifications and activate the Pivotal CF Mobile Services push services SDK.
 *
 * You must call [PCFPush registerForPushNotifications] in order for your change to take effect.
 *
 * @param notificationTypes the type of alert that the user can receive when they receive a remote notification.
 */
+ (void) setRemoteNotificationTypes:(UIRemoteNotificationType)notificationTypes;

/**
 * Sets the tags that the device should be subscribed to. Always provide the entire
 * list of tags that the device should be subscribed to. If the device is already subscribed to
 * some tags and those tags are not provided when calling this method again then those
 * tags will be unsubscribed.
 *
 * You must call [PCFPush registerForPushNotifications] in order for your change to take effect.
 *
 * @param tags Provides the list of tags the device should subscribe to. Allowed to be `nil` or empty.
 */
+ (void) setTags:(NSSet *)tags;

/**
 * Sets the device alias used to identify the device in the server. Typically you would use
 * the device name (i.e.: [[UIDevice currentDevice] name]), but the usage of this field
 * is application-defined and could be anything.
 *
 * You must call [PCFPush registerForPushNotifications] in order for your change to take effect.
 *
 * @param deviceAlias Provides the list of tags the device should subscribe to. Allowed to be `nil` or empty.
 */
+ (void) setDeviceAlias:(NSString *)deviceAlias;

/**
 * @param success block that will be executed if registration finishes successfully. This callback will
 *                be called on the main queue.  May be `nil`.
 *
 * @param failure block that will be executed if registration fails. This callback will be called on the main
 *                queue.  May be `nil`.
 */
+ (void) setCompletionBlockWithSuccess:(void (^)(void))success
                               failure:(void (^)(NSError *))failure;

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
                                 failure:(void (^)(NSError *))failure;
@end
