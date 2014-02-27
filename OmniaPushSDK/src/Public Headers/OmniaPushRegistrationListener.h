//
//  OmniaPushRegistrationListener.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-29.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Defines a protocol that can be used to find out if registration attempts pass or fail.
 * Note that if the APNS registration times out then it is possible that neither of these
 * callbacks might be called.
 */
@protocol OmniaPushRegistrationListener <NSObject>

/**
 * Called after APNS and back-end registration succeed.
 */
- (void) registrationSucceeded;

/**
 * Called if either APNS or back-end registration fail.
 *
 * @note It is possible for APNS registration to fail silently and never call back.  These
 *       scenarios could be considered failures, but will never be reported.
 *
 * @param error The error that caused registration to fail.  See the file `OmniaPushErrors.h`
 *              for the error definitions specific to the Omnia Push Client SDK.
 */
- (void) registrationFailedWithError:(NSError*)error;

@end
