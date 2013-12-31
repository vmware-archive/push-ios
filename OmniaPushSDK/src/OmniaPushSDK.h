//
//  OmniaPushSDK.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-31.
//  Copyright (c) 2013 Omnia. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OmniaPushSDK : NSObject

+ (OmniaPushSDK*) registerForRemoteNotificationTypes:(UIRemoteNotificationType)remoteNotificationTypes;

@end
