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
#import "OmniaPushErrors.h"

#define DEFAULT_DELAY_TIME_IN_SECONDS 60ull

@interface OmniaPushSDKInstance ()

@property (nonatomic) UIApplication *application;
@property (nonatomic) NSObject<OmniaPushAPNSRegistrationRequest> *registrationRequest;
@property (nonatomic) id<UIApplicationDelegate> currentApplicationDelegate;
@property (nonatomic) NSProxy<OmniaPushAppDelegateProxy> *appDelegateProxy;
@property (nonatomic) id<OmniaPushRegistrationListener> listener;
@property (nonatomic) dispatch_queue_t queue;
@property (nonatomic) BOOL didRegistrationReturn;
@property (nonatomic) BOOL didRegistrationTimeout;
@property (nonatomic) int64_t timeout;
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
        self.didRegistrationReturn = NO;
        self.didRegistrationTimeout = NO;
        self.timeout = DEFAULT_DELAY_TIME_IN_SECONDS * NSEC_PER_SEC;
    }
    return self;
}

- (void) changeTimeout:(int64_t)newTimeoutInMilliseconds
{
    self.timeout = newTimeoutInMilliseconds * NSEC_PER_MSEC;
}

- (void) registerForRemoteNotificationTypes:(UIRemoteNotificationType)types
                                   listener:(id<OmniaPushRegistrationListener>)listener
{
    // Send registration request
    dispatch_async(self.queue, ^{
        self.currentApplicationDelegate = self.application.delegate;
        self.application.delegate = self.appDelegateProxy;
        self.listener = listener;
        [self.appDelegateProxy registerForRemoteNotificationTypes:types listener:self];

        dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, self.timeout);
        
        // Check for time out
        dispatch_after(delayTime, self.queue, ^(void){
            if (!self.didRegistrationReturn) {
                [self registrationTimedOutForApplication:self.application];
            }
        });
    });
}

- (void) application:(UIApplication*)application
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
    dispatch_async(self.queue, ^{
        [self registrationCompleteForApplication:application];
        if (self.listener) {
            [self.listener application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
        }
    });
}

- (void) application:(UIApplication*)application
    didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
    dispatch_async(self.queue, ^{
        [self registrationCompleteForApplication:application];
        if (self.listener) {
            [self.listener application:application didFailToRegisterForRemoteNotificationsWithError:error];
        }
    });
}

- (void) registrationCompleteForApplication:(UIApplication*)application
{
    OmniaPushLog(@"Library initialized.");
    self.didRegistrationReturn = YES;
    [self cleanupAfterRegistrationAttempt:application];
}

- (void) registrationTimedOutForApplication:(UIApplication*)application
{
    OmniaPushLog(@"Registration attempt timed out.");
    self.didRegistrationTimeout = YES;
    [self cleanupAfterRegistrationAttempt:application];
    if (self.listener) {
        NSDictionary *errorUserInfo = @{NSLocalizedDescriptionKey:@"Registration attempt with APNS has timed out."};
        [self.listener application:application didFailToRegisterForRemoteNotificationsWithError:[NSError errorWithDomain:OmniaPushErrorDomain code:OmniaPushRegistrationTimeoutError userInfo:errorUserInfo]];
    }
}

- (void) cleanupAfterRegistrationAttempt:(UIApplication*)application
{
    [self.appDelegateProxy cancelRegistration];
    application.delegate = self.currentApplicationDelegate;
}

@end
