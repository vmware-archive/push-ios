//
//  OmniaPushAppDelegateProxyListener.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-30.
//  Copyright (c) 2013 Omnia. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OmniaPushAppDelegateProxyListener <NSObject>

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken;
- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error;

@end
