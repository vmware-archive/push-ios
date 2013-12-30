//
//  OmniaPushAPNSRegistrationRequestImpl.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-19.
//  Copyright (c) 2013 Omnia. All rights reserved.
//

#import "OmniaPushAPNSRegistrationRequestImpl.h"

@implementation OmniaPushAPNSRegistrationRequestImpl

// TODO: should this class also accept the UIApplication to use?  It would be more dependency-injectiony.

- (void) registerForRemoteNotificationTypes:(UIRemoteNotificationType)types {
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:types];
}

@end
