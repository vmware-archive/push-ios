//
//  OmniaPushSDK.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-13.
//  Copyright (c) 2013 Omnia. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OmniaPushRegistrationListener.h"

@protocol OmniaPushAPNSRegistrationRequest;
@protocol OmniaPushAppDelegateProxy;
@protocol OmniaPushRegistrationListener;

@interface OmniaPushSDKInstance : NSObject<OmniaPushRegistrationListener>

- (instancetype) initWithApplication:(UIApplication*)application
                 registrationRequest:(NSObject<OmniaPushAPNSRegistrationRequest>*)registrationRequest
                    appDelegateProxy:(NSProxy<OmniaPushAppDelegateProxy>*)appDelegateProxy
                               queue:(dispatch_queue_t)queue;

- (void) registerForRemoteNotificationTypes:(UIRemoteNotificationType)types listener:(id<OmniaPushRegistrationListener>)listener;

@end
