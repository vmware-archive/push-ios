//
//  OmniaPushAppDelegateProxy.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-18.
//  Copyright (c) 2013 Omnia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OmniaPushAppDelegateProxy.h"
#import "OmniaPushAPNSRegistrationRequestOperation.h"

@interface OmniaPushAppDelegateProxyImpl : NSObject<OmniaPushAppDelegateProxy>

@property (nonatomic, readonly) UIApplication *application;
@property (nonatomic, readonly) NSObject<UIApplicationDelegate> *applicationDelegate;
@property (nonatomic, readonly) OmniaPushAPNSRegistrationRequestOperation *registrationRequest;

- (instancetype) initWithApplication:(UIApplication*)application
         originalApplicationDelegate:(NSObject<UIApplicationDelegate>*)originalApplicationDelegate
                 registrationRequest:(OmniaPushAPNSRegistrationRequestOperation*)registrationRequest;

@end
