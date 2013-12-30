//
//  OmniaPushSDK.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-13.
//  Copyright (c) 2013 Omnia. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OmniaPushAppDelegateProxyListener.h"

@protocol OmniaPushAPNSRegistrationRequest;
@protocol OmniaPushAppDelegateProxy;

@interface OmniaPushSDKInstance : NSObject<OmniaPushAppDelegateProxyListener>

- (instancetype) initWithApplication:(UIApplication*)application
                 registrationRequest:(NSObject<OmniaPushAPNSRegistrationRequest>*)registrationRequest
                    appDelegateProxy:(NSProxy<OmniaPushAppDelegateProxy>*)appDelegateProxy;

- (void) registerForRemoteNotificationTypes:(UIRemoteNotificationType)types;

@end
