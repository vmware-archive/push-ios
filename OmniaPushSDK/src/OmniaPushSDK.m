//
//  OmniaPushSDK.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-31.
//  Copyright (c) 2013 Omnia. All rights reserved.
//

#import "OmniaPushSDK.h"
#import "OmniaPushAPNSRegistrationRequestImpl.h"
#import "OmniaPushAppDelegateProxyImpl.h"
#import "OmniaPushSDKInstance.h"

static OmniaPushSDK* sharedInstance = nil;
static dispatch_once_t once_token = 0;

@interface OmniaPushSDK ()

@property (nonatomic) OmniaPushSDKInstance *sdkInstance;

@end

@implementation OmniaPushSDK

+ (OmniaPushSDK*) registerForRemoteNotificationTypes:(UIRemoteNotificationType)remoteNotificationTypes {
    dispatch_once(&once_token, ^{
        if (sharedInstance == nil) {
            sharedInstance = [[OmniaPushSDK alloc] initWithRemoteNotificationTypes:remoteNotificationTypes];
        }
    });
    return sharedInstance;
}

+ (void) setSharedInstance:(OmniaPushSDK*)newSharedInstance {
    sharedInstance = newSharedInstance;
    once_token = 0;
}

- (instancetype) initWithRemoteNotificationTypes:(UIRemoteNotificationType)remoteNotificationTypes {
    self = [super init];
    if (self) {
        NSObject<OmniaPushAPNSRegistrationRequest> *registrationRequest = [[OmniaPushAPNSRegistrationRequestImpl alloc] init];
        NSProxy<OmniaPushAppDelegateProxy> *appDelegateProxy = [[OmniaPushAppDelegateProxyImpl alloc] initWithAppDelegate:[UIApplication sharedApplication].delegate registrationRequest:registrationRequest];
        self.sdkInstance = [[OmniaPushSDKInstance alloc] initWithApplication:[UIApplication sharedApplication] registrationRequest:registrationRequest appDelegateProxy:appDelegateProxy];
        [self.sdkInstance registerForRemoteNotificationTypes:remoteNotificationTypes];
    }
    return self;
}

@end
