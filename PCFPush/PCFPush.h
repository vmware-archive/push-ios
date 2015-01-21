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
 * You *MUST* call one of these 'registerForPushNotifications' methods every time the application is started.
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
 *
 * Optional: You can also set a device alias used to identify the device in the server. Typically you would use
 * the device name (i.e.: [[UIDevice currentDevice] name]), but the usage of this field
 * is application-defined and could be anything.
 *
 * Optional: If you know which tags you want to subscribe to then you can subscribe to them at the same time
 * that you register with your device.  If you want to subscribe to other tags later in the runtime of your
 * app then you can use the subscribeToTags method.  Note that you must have registered successfully
 * before you can use the subscribeToTags method.
 */
+ (void) registerForPushNotifications;
+ (void) registerForPushNotificationsWithTags:(NSSet *)tags;
+ (void) registerForPushNotificationsWithDeviceAlias:(NSString *)deviceAlias;
+ (void) registerForPushNotificationsWithDeviceAlias:(NSString *)deviceAlias tags:(NSSet *)tags;

/**
 * IMPORTANT!  You must call this method from your -application:didRegisterForRemoteNotificationWithDeviceToken:
 * method in your UIApplicationDelegate in order to successfully register your device for push notifications
 * with Pivotal CF Push.
 *
 * example:
 *
 * - (void) application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
 * {
 *     NSLog(@"APNS registration succeeded!");
 *
 *     // Continue registration with PCF Push
 *     [PCFPush APNSRegistrationSucceededWithDeviceToken:deviceToken
 *     success:^{
 *          // registration with Pivotal CF completed successfully.
 *     } failure:^(NSError *error) {
 *          // registration with Pivotal CF FAILED.
 *     }];
 * }
 *
 */
+ (void)APNSRegistrationSucceededWithDeviceToken:(NSData *)deviceToken
                                         success:(void (^)(void))success
                                         failure:(void (^)(NSError *))failure;

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
 * The device must be registered before you may call this (i.e: you must have called one of the
 * following methods and waited for the response to return successfully):
 *
 *     registerForPushNotifications;
 *     registerForPushNotificationsWithTags:(NSSet *)tags;
 *     registerForPushNotificationsWithDeviceAlias:(NSString *)deviceAlias;
 *     registerForPushNotificationsWithDeviceAlias:(NSString *)deviceAlias tags:(NSSet *)tags;
 *
 * @param tags Provides the list of tags the device should subscribe to. Allowed to be `nil` or empty.
 */
+ (void) subscribeToTags:(NSSet *)tags success:(void (^)(void))success failure:(void (^)(NSError*))failure;

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
