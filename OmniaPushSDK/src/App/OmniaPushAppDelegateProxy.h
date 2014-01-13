//
//  OmniaPushAppDelegateProxy.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-20.
//  Copyright (c) 2013 Omnia. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OmniaPushRegistrationListener;

@protocol OmniaPushAppDelegateProxy <UIApplicationDelegate>

- (void) registerForRemoteNotificationTypes:(UIRemoteNotificationType)types;
- (void) cancelRegistration;

@end
