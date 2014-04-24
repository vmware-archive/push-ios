//
//  PCFPushSDK.h
//  PCFPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-31.
//  Copyright (c) 2013 Pivotal. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PCFSDK.h"

@class PCFParameters;

#warning - TODO: Complete documentation

/**
 * Primary entry point for the CF Push Client SDK library.
 *
 * Usage: see `README.md`
 *
 */
@interface PCFPushSDK : PCFSDK

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
