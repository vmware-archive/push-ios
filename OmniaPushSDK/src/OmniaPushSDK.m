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

// SDK instance variables
static OmniaPushSDK* sharedInstance = nil;
static dispatch_once_t once_token = 0;
static NSObject<OmniaPushAPNSRegistrationRequest> *registrationRequest;
static NSProxy<OmniaPushAppDelegateProxy> *appDelegateProxy;
static UIApplication *application;
static dispatch_queue_t queue;
static id<OmniaPushRegistrationListener> _listener;

// Global constant storage
NSString* const OmniaPushErrorDomain = @"OmniaPushErrorDomain";

@interface OmniaPushSDK ()

@property (nonatomic) OmniaPushSDKInstance *sdkInstance;

@end

@implementation OmniaPushSDK

+ (OmniaPushSDK*) registerForRemoteNotificationTypes:(UIRemoteNotificationType)remoteNotificationTypes
{
    return [OmniaPushSDK registerForRemoteNotificationTypes:remoteNotificationTypes listener:nil];
}

// NOTE:  the application delegate will still be called after registration completes, except if the
// registration attempt times out.  The listener will be regardless if the registration succeeds, fails,
// or times out.  The default time out interval is 60 seconds.

+ (OmniaPushSDK*) registerForRemoteNotificationTypes:(UIRemoteNotificationType)remoteNotificationTypes
                                            listener:(id<OmniaPushRegistrationListener>)listener
{
    dispatch_once(&once_token, ^{
        if (sharedInstance == nil) {
            sharedInstance = [[OmniaPushSDK alloc] initWithRemoteNotificationTypes:remoteNotificationTypes listener:listener];
        }
    });
    return sharedInstance;
}

- (instancetype) initWithRemoteNotificationTypes:(UIRemoteNotificationType)remoteNotificationTypes
                                        listener:(id<OmniaPushRegistrationListener>)listener
{
    self = [super init];
    if (self) {
        _listener = listener;
        [OmniaPushSDK setupQueue:nil];
        [OmniaPushSDK setupRegistrationRequest:nil];
        [OmniaPushSDK setupApplication:nil];
        [OmniaPushSDK setupAppDelegateProxy:nil];
        self.sdkInstance = [[OmniaPushSDKInstance alloc] initWithApplication:[UIApplication sharedApplication] registrationRequest:registrationRequest appDelegateProxy:appDelegateProxy queue:queue];
        [self.sdkInstance registerForRemoteNotificationTypes:remoteNotificationTypes listener:self]; // TODO - wait for registration to complete?
    }
    return self;
}

#pragma mark - OmniaPushRegistrationListener callbacks

- (void)application:(UIApplication*)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
    if (_listener) {
        [_listener application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
    }
}

- (void)application:(UIApplication*)application
didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
    if (_listener) {
        [_listener application:application didFailToRegisterForRemoteNotificationsWithError:error];
    }
}

#pragma mark - Unit test helpers

// Used by unit tests to provide a fake singleton or to reset this singleton for following tests
+ (void) setSharedInstance:(OmniaPushSDK*)newSharedInstance {
    _listener = nil;
    application = nil;
    appDelegateProxy = nil;
    registrationRequest = nil;
    queue = nil;
    sharedInstance = newSharedInstance;
    once_token = 0;
}

// Used by unit tests to provide a dispatch queue
+ (void) setupQueue:(dispatch_queue_t)testQueue {
    if (queue) return;
    if (testQueue == nil) {
        queue = dispatch_queue_create("OmniaPushSDKWorkerQueue", NULL);
    } else {
        queue = testQueue;
    }
}

// Used by unit tests to provide fake registration request objects
+ (void) setupRegistrationRequest:(NSObject<OmniaPushAPNSRegistrationRequest>*)testRegistrationRequest {
    if (registrationRequest) return;
    if (testRegistrationRequest == nil) {
        registrationRequest = [[OmniaPushAPNSRegistrationRequestImpl alloc] init];
    } else {
        registrationRequest = testRegistrationRequest;
    }
}

// Used by unit tests to provide fake application objects
+ (void) setupApplication:(UIApplication*)testApplication {
    if (application) return;
    if (testApplication == nil) {
        application = [UIApplication sharedApplication];
    } else {
        application = testApplication;
    }
}

// Used by unit tests to provide fake app delegate proxy objects
+ (void) setupAppDelegateProxy:(NSProxy<OmniaPushAppDelegateProxy>*)testAppDelegateProxy {
    if (appDelegateProxy) return;
    if (testAppDelegateProxy == nil) {
        appDelegateProxy = [[OmniaPushAppDelegateProxyImpl alloc] initWithAppDelegate:application.delegate registrationRequest:registrationRequest];
    } else {
        appDelegateProxy = testAppDelegateProxy;
    }
}

@end
