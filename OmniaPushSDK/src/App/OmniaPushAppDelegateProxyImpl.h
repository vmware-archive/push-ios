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

@interface OmniaPushAppDelegateProxyImpl : NSProxy<OmniaPushAppDelegateProxy>

@property (nonatomic) NSObject<UIApplicationDelegate> *appDelegate;
@property (nonatomic) OmniaPushAPNSRegistrationRequestOperation *registrationRequest;
@property (nonatomic, weak) id<OmniaPushRegistrationListener> listener;

- (instancetype) initWithAppDelegate:(NSObject<UIApplicationDelegate>*)appDelegate
                 registrationRequest:(OmniaPushAPNSRegistrationRequestOperation*)registrationRequest;

@end
