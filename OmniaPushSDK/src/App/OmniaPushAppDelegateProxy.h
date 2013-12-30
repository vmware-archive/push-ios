//
//  OmniaPushAppDelegateProxy.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-20.
//  Copyright (c) 2013 Omnia. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OmniaPushAppDelegateProxyListener;

@protocol OmniaPushAppDelegateProxy <UIApplicationDelegate>

- (void) registerForRemoteNotificationTypes:(UIRemoteNotificationType)types listener:(id<OmniaPushAppDelegateProxyListener>)proxyListener;

@end
