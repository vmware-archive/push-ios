//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MSSParameters;

@interface MSSBase : NSObject

/**
 * Sets the registration parameters of the application for receiving push notifications. If some of the
 * registration parameters are different then the last successful registration then the device will be re-registered with the new parameters.
 *
 * @param parameters Provides the parameters required for registration.  May not be `nil`.
 *
 */
+ (void)setRegistrationParameters:(MSSParameters *)parameters;

@end
