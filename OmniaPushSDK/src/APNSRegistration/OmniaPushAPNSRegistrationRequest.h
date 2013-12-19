//
//  OmniaPushAPNSRegistrationRequest.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-18.
//  Copyright (c) 2013 Omnia. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OmniaPushAPNSRegistrationRequest <NSObject>

- (void) registerForRemoteNotificationTypes:(UIRemoteNotificationType)types;

@end
