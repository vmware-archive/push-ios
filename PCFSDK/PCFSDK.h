//
//  PCFSDK.h
//  
//
//  Created by DX123-XL on 2014-04-24.
//
//

#import <Foundation/Foundation.h>

@class PCFParameters;

@interface PCFSDK : NSObject

/**
 * Sets the registration parameters of the application for receiving push notifications. If some of the
 * registration parameters are different then the last successful registration then the device will be re-registered with the new parameters.
 *
 * @param parameters Provides the parameters required for registration.  May not be `nil`.
 *
 */
+ (void)setRegistrationParameters:(PCFParameters *)parameters;

+ (BOOL)analyticsEnabled;

+ (void)setAnalyticsEnabled:(BOOL)enabled;

#pragma mark - App lifecycle notification

+ (void)appDidFinishLaunchingNotification:(NSNotification *)notification;

+ (void)appWillTerminateNotification:(NSNotification *)notification;

@end
