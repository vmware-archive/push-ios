//
//  OmniaPushSDK.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-31.
//  Copyright (c) 2013 Pivotal. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OmniaPushRegistrationParameters;

/**
 * Primary entry point for the Omnia Push Client SDK library.
 *
 * Usage: see `README.md`
 *
 */
@interface OmniaPushSDK : NSObject

/**
 * Asynchronously registers the device and application for receiving push notifications.  If the application
 * is already registered then this call will do nothing.  If some of the registration parameters are different
 * then the last successful registration then the device will be re-registered with the new parameters.  Only
 * the first call to either of the register methods will do anything.  Only one registration attempt is allowed
 * per lifetime of the process.
 *
 * @param parameters Provides the parameters required for registration.  May not be `nil`.
 */
+ (void)registerWithParameters:(OmniaPushRegistrationParameters *)parameters;

/**
 * Asynchronously registers the device and application for receiving push notifications.  If the application
 * is already registered then this call will do nothing.  If some of the registration parameters are different
 * then the last successful registration then the device will be re-registered with the new parameters.  Only
 * the first call to either of the register methods will do anything.  Only one registration attempt is allowed
 * per lifetime of the process.
 *
 * @param parameters Provides the parameters required for registration.  May not be `nil`.
 *
 * @param success block that will be executed if registration finishes successfully. This callback will
 *                 be called on the main thread.  May be `nil`.
 *
 * @param failure block that will be executed if registration fails. This callback will be called on the main
 *                 thread.  May be `nil`.
 */

#warning - Fix documentation
+ (void)registerWithParameters:(OmniaPushRegistrationParameters *)parameters
                       success:(void (^)(void))success
                       failure:(void (^)(NSError *error))failure;

@end
