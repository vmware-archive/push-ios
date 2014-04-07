//
//  PCFPushSDK.h
//  PCFPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-31.
//  Copyright (c) 2013 Pivotal. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PCFPushParameters;

/**
 * Primary entry point for the CF Push Client SDK library.
 *
 * Usage: see `README.md`
 *
 */
@interface PCFPushSDK : NSObject

#warning - Fix documentation

/**
 * Sets the registration parameters of the application for receiving push notifications. If some of the
 * registration parameters are different then the last successful registration then the device will be re-registered with the new parameters.
 *
 * @param parameters Provides the parameters required for registration.  May not be `nil`.
 *
 * @param success block that will be executed if registration finishes successfully. This callback will
 *                be called on the main queue.  May be `nil`.
 *
 * @param failure block that will be executed if registration fails. This callback will be called on the main
 *                queue.  May be `nil`.
 */

+ (void)setRegistrationParameters:(PCFPushParameters *)parameters
                          success:(void (^)(void))success
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
+ (void)unregisterSuccess:(void (^)(void))success
                  failure:(void (^)(NSError *error))failure;


+ (BOOL)analyticsEnabled;

+ (void)setAnalyticsEnabled:(BOOL)enabled;

@end
