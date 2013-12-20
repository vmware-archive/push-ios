//
//  OmniaPushSDK.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-13.
//  Copyright (c) 2013 Omnia. All rights reserved.
//

#import "OmniaPushSDKInstance.h"
#import "OmniaPushDebug.h"
#import "OmniaPushAppDelegateProxyImpl.h"
#import "OmniaPushAPNSRegistrationRequestImpl.h"

@interface OmniaPushSDKInstance ()

@property (nonatomic) id<UIApplicationDelegate> currentApplicationDelegate;
@property (nonatomic) OmniaPushAppDelegateProxyImpl *proxy;

@end

@implementation OmniaPushSDKInstance

- (instancetype) init {
    self = [super init];
    if (self) {
        
        self.currentApplicationDelegate = [UIApplication sharedApplication].delegate;
        NSObject<OmniaPushAPNSRegistrationRequest> *registrationRequest = [[OmniaPushAPNSRegistrationRequestImpl alloc] init];
        self.proxy = [[OmniaPushAppDelegateProxyImpl alloc] initWithAppDelegate:self.currentApplicationDelegate registrationRequest:registrationRequest];
        [UIApplication sharedApplication].delegate = self.proxy;
        [self.proxy registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert|UIRemoteNotificationTypeBadge];
        // TODO - accept notification types as method argument
        
        OmniaPushLog(@"Library initialized.");
    }
    return self;
}

@end
