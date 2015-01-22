//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * Primary entry point for the PCF Push Client SDK library.
 *
 * Usage: see `README.md`
 */
@interface PCFPush : NSObject

/**
 * Registers device for push notifications.
 *
 * In order to register for push notifications you must first register for push notifications with the Apple Push
 * Notifications Service (APNS) by calling [UIApplication.sharedApplication registerForRemoteNotifications].  After
 * Apple registration succeeds then Apple will call the -application:didRegisterForRemoteNotificationWithDeviceToken:
 * method in your application delegate method.  Pass that device token to PCF via the
 * -registerForPCFPushNotificationsWithDeviceToken method.
 *
 * You *MUST* call the 'registerForPCFPushNotificationsWithDeviceToken' method every time you have successfully
 * registered for push notifications with APNS.
 *
 * Apple recommends calling [UIApplication.sharedApplication registerForRemoteNotifications] every time you
 * start your application.
 *
 * To provide parameters, you must provide a PLIST file called "Pivotal.plist" with the following registration
 * parameters:
 *
 *    pivotal.push.serviceUrl                  - The URL of the PCF Push Server
 *    pivotal.push.variantUuid.development     - The variant UUID of your push development variant.
 *    pivotal.push.variantSecret.development   - The variant secret of your push development variant.
 *    pivotal.push.variantUuid.production      - The variant UUID of your push production variant.
 *    pivotal.push.variantSecret.production    - The variant secret of your push production variant.
 *
 * None of the above values may be `nil`.  None of the above values may be empty.
 *
 * The client SDK uses the development variant if the application is compiled in debug mode.
 *
 * The client SDK uses the production variant if the application is compiled in release mode.
 *
 * Optional: You can also set a device alias used to identify the device in the server. Typically you would use
 * the device name (i.e.: UIDevice.currentDevice.name), but the usage of this field
 * is application-defined and could be anything.
 *
 * Optional: If you know which tags you want to subscribe to then you can subscribe to them at the same time
 * that you register with your device.  If you want to subscribe to other tags later in the runtime of your
 * app then you can use the subscribeToTags method.  Note that you must have registered successfully
 * before you can use the subscribeToTags method.
 *
 * example:
 *
 * - (void) application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
 * {
 *     NSLog(@"APNS registration succeeded!");
 *
 *     // Continue registration with PCF Push
 *     [PCFPush registerForPCFPushNotificationsWithDeviceToken: deviceToken
 *                                                        tags: [NSSet setWithArray:@[ LIST_OF_TAGS_TO_SUBSCRIBE_TO ]
 *                                                 deviceAlias: UIDevice.currentDevice.name // or whatever device alias you want to use
 *                                                     success: ^{  success callback }
 *                                                     failure: ^(NSError *error) {  error callback }
 *     ];
 * }
 *
 */
+ (void)registerForPCFPushNotificationsWithDeviceToken:(NSData *)deviceToken
                                                  tags:(NSSet *)tags
                                           deviceAlias:(NSString *)deviceAlias
                                               success:(void (^)(void))success
                                               failure:(void (^)(NSError *))failure;

/**
 * Sets the tags that the device should be subscribed to. Always provide the entire
 * list of tags that the device should be subscribed to. If the device is already subscribed to
 * some tags and those tags are not provided when calling this method again then those
 * tags will be unsubscribed.
 *
 * The device must be registered before you may call subscribeToTags (i.e: you must have called the
 * registerForPCFPushNotificationsWithDeviceToken method and waited for the response to return successfully).
 *
 * @param tags Provides the list of tags the device should subscribe to. Allowed to be `nil` or empty.
 *
 * @param success block that will be executed if subscription is successful. This callback will be called on
 *                the main queue. May be 'nil'.
 *
 * @param failure block that will be executed if subscription fails. This callback will be called on the main
 *                queue. May be 'nil'.
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
+ (void)unregisterFromPCFPushNotificationsWithSuccess:(void (^)(void))success
                                              failure:(void (^)(NSError *))failure;
@end