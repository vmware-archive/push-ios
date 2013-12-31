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
static NSObject<OmniaPushAPNSRegistrationRequest> *registrationRequest;
static NSProxy<OmniaPushAppDelegateProxy> *appDelegateProxy;
static UIApplication *application;

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

- (instancetype) initWithRemoteNotificationTypes:(UIRemoteNotificationType)remoteNotificationTypes {
    self = [super init];
    if (self) {
        [OmniaPushSDK setupRegistrationRequest:nil];
        [OmniaPushSDK setupApplication:nil];
        [OmniaPushSDK setupAppDelegateProxy:nil];
        self.sdkInstance = [[OmniaPushSDKInstance alloc] initWithApplication:[UIApplication sharedApplication] registrationRequest:registrationRequest appDelegateProxy:appDelegateProxy];
        [self.sdkInstance registerForRemoteNotificationTypes:remoteNotificationTypes];
    }
    return self;
}

#pragma mark - Unit test helpers

// Used by unit tests to provide a fake singleton or to reset this singleton for following tests
+ (void) setSharedInstance:(OmniaPushSDK*)newSharedInstance {
    application = nil;
    appDelegateProxy = nil;
    registrationRequest = nil;
    sharedInstance = newSharedInstance;
    once_token = 0;
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
