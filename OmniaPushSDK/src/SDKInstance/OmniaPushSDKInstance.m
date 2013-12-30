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

@property (nonatomic) UIApplication *application;
@property (nonatomic) NSObject<OmniaPushAPNSRegistrationRequest> *registrationRequest;
@property (nonatomic) id<UIApplicationDelegate> currentApplicationDelegate;
@property (nonatomic) NSProxy<OmniaPushAppDelegateProxy> *appDelegateProxy;

@end

@implementation OmniaPushSDKInstance

- (instancetype) initWithApplication:(UIApplication*)application
                 registrationRequest:(NSObject<OmniaPushAPNSRegistrationRequest>*)registrationRequest
                    appDelegateProxy:(NSProxy<OmniaPushAppDelegateProxy>*)appDelegateProxy
{
    self = [super init];
    if (self) {
        if (application == nil) {
            [NSException raise:NSInvalidArgumentException format:@"application may not be nil"];
        }
        if (registrationRequest == nil) {
            [NSException raise:NSInvalidArgumentException format:@"registrationRequest may not be nil"];
        }
        if (appDelegateProxy == nil) {
            [NSException raise:NSInvalidArgumentException format:@"appDelegateProxy may not be nil"];
        }
        self.application = application;
        self.registrationRequest = registrationRequest;
        self.appDelegateProxy = appDelegateProxy;
    }
    return self;
}

- (void) registerForRemoteNotificationTypes:(UIRemoteNotificationType)types {
    self.currentApplicationDelegate = self.application.delegate;
    self.application.delegate = self.appDelegateProxy;
    [self.appDelegateProxy registerForRemoteNotificationTypes:types];
    OmniaPushLog(@"Library initialized.");
    // TODO - restore application delegate after registration is complete
}


@end
