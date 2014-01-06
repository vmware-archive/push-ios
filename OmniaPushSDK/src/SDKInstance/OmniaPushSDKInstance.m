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
@property (nonatomic) id<OmniaPushRegistrationListener> listener;
@property (nonatomic) dispatch_queue_t queue;
@property (nonatomic) BOOL didRegistrationReturn;

@end

@implementation OmniaPushSDKInstance

- (instancetype) initWithApplication:(UIApplication*)application
                 registrationRequest:(NSObject<OmniaPushAPNSRegistrationRequest>*)registrationRequest
                    appDelegateProxy:(NSProxy<OmniaPushAppDelegateProxy>*)appDelegateProxy
                               queue:(dispatch_queue_t)queue
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
        if (queue == nil) {
            [NSException raise:NSInvalidArgumentException format:@"queue may not be nil"];
        }
        self.application = application;
        self.registrationRequest = registrationRequest;
        self.appDelegateProxy = appDelegateProxy;
        self.queue = queue;
    }
    return self;
}

- (void) registerForRemoteNotificationTypes:(UIRemoteNotificationType)types
                                   listener:(id<OmniaPushRegistrationListener>)listener
{
    dispatch_async(self.queue, ^{
        self.currentApplicationDelegate = self.application.delegate;
        self.application.delegate = self.appDelegateProxy;
        self.listener = listener;
        [self.appDelegateProxy registerForRemoteNotificationTypes:types listener:self];
    });
}

- (void)application:(UIApplication*)application
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
    dispatch_async(self.queue, ^{
        [self registrationCompleteForApplication:application];
        if (self.listener) {
            [self.listener application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
        }
    });
}

- (void)application:(UIApplication*)application
    didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
    dispatch_async(self.queue, ^{
        [self registrationCompleteForApplication:application];
        if (self.listener) {
            [self.listener application:application didFailToRegisterForRemoteNotificationsWithError:error];
        }
    });
}

- (void)registrationCompleteForApplication:(UIApplication*)application
{
    self.didRegistrationReturn = YES;
    application.delegate = self.currentApplicationDelegate;
    OmniaPushLog(@"Library initialized.");
}

@end
