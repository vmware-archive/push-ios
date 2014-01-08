//
//  OmniaPushSDK.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-31.
//  Copyright (c) 2013 Omnia. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OmniaPushRegistrationListener.h"
#import "OmniaPushErrors.h"

@interface OmniaPushSDK : NSObject<OmniaPushRegistrationListener>

+ (OmniaPushSDK*) registerForRemoteNotificationTypes:(UIRemoteNotificationType)remoteNotificationTypes;
+ (OmniaPushSDK*) registerForRemoteNotificationTypes:(UIRemoteNotificationType)remoteNotificationTypes listener:(id<OmniaPushRegistrationListener>)listener;

@end
