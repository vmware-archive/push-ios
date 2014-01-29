//
//  OmniaPushRegistrationListener.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-29.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OmniaPushRegistrationListener <NSObject>

- (void) registrationSucceeded;
- (void) registrationFailedWithError:(NSError*)error;

@end
