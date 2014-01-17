//
//  OmniaPushAppDelegateProxy.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-18.
//  Copyright (c) 2013 Omnia. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OmniaPushAppDelegateProxy : NSObject

- (instancetype) initWithApplication:(UIApplication*)application
         originalApplicationDelegate:(NSObject<UIApplicationDelegate>*)originalApplicationDelegate;
- (void) registerForRemoteNotificationTypes:(UIRemoteNotificationType)notificationTypes;
- (void) cleanup;

@end
