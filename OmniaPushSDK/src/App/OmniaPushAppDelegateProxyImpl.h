//
//  OmniaPushAppDelegateProxy.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-18.
//  Copyright (c) 2013 Omnia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OmniaPushAppDelegateProxy.h"

@protocol OmniaPushAPNSRegistrationRequest;

@interface OmniaPushAppDelegateProxyImpl : NSProxy<UIApplicationDelegate, OmniaPushAppDelegateProxy>

@property (nonatomic) NSObject<UIApplicationDelegate> *appDelegate;
@property (nonatomic) NSObject<OmniaPushAPNSRegistrationRequest> *registrationRequest;

- (instancetype) initWithAppDelegate:(NSObject<UIApplicationDelegate>*)appDelegate
                 registrationRequest:(NSObject<OmniaPushAPNSRegistrationRequest>*)registrationRequest;

@end
