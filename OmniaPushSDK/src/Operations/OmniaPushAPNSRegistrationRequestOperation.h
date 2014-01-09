//
//  OmniaPushAPNSRegistrationRequestOperation.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-19.
//  Copyright (c) 2013 Omnia. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OmniaPushAPNSRegistrationRequestOperation : NSOperation

@property (nonatomic, readonly, assign) UIRemoteNotificationType notificationTypes;
@property (nonatomic, readonly) UIApplication *application;

- (instancetype) initForRegistrationForRemoteNotificationTypes:(UIRemoteNotificationType)types
                                                   application:(UIApplication*)application;

@end
