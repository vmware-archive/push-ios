//
//  OmniaPushSDK.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-31.
//  Copyright (c) 2013 Omnia. All rights reserved.
//

#import "OmniaPushSDK.h"
#import "OmniaPushAPNSRegistrationRequestOperation.h"
#import "OmniaPushAppDelegateProxyImpl.h"

// Global constant storage
NSString* const OmniaPushErrorDomain = @"OmniaPushErrorDomain";

// SDK instance variables
static OmniaPushSDK* sharedInstance = nil;
static OmniaPushAPNSRegistrationRequestOperation *registrationRequest = nil;
static dispatch_once_t once_token = 0;
static UIApplication *application = nil;

@interface OmniaPushSDK ()

@property (nonatomic, strong) id<UIApplicationDelegate> originalApplicationDelegate;
@property (nonatomic, strong) NSProxy<OmniaPushAppDelegateProxy> *appDelegateProxy;

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
        [OmniaPushSDK setupApplication:nil];
        [OmniaPushSDK setupRegistrationRequest:nil];
        self.appDelegateProxy = [[OmniaPushAppDelegateProxyImpl alloc] initWithAppDelegate:application.delegate registrationRequest:registrationRequest];
        [self registerForRemoteNotificationTypes:remoteNotificationTypes listener:listener]; // TODO - wait for registration to complete?
    }
    return self;
}

- (void) registerForRemoteNotificationTypes:(UIRemoteNotificationType)remoteNotificationTypes
                                   listener:(id<OmniaPushRegistrationListener>)listener
{
    // Send registration request
    @synchronized(self) {
        self.originalApplicationDelegate = application.delegate;
        application.delegate = self.appDelegateProxy;
        [self.appDelegateProxy registerForRemoteNotificationTypes:remoteNotificationTypes listener:listener]; // TODO - should be an operation
    }
    // TODO - restore application delegate upon application shutdownx
}

- (void) cleanupInstance
{
    @synchronized(self) {
        if (application && self.originalApplicationDelegate) {
            application.delegate = self.originalApplicationDelegate;
        }
        self.appDelegateProxy = nil;
        self.originalApplicationDelegate = nil;
    }
}

#pragma mark - Unit test helpers

// Used by unit tests to provide a fake singleton or to reset this singleton for following tests
+ (void) setSharedInstance:(OmniaPushSDK*)newSharedInstance {
    if (sharedInstance) {
        [sharedInstance cleanupInstance];
        sharedInstance = nil;
    }
    once_token = 0;
    application = nil;
    registrationRequest = nil;
    sharedInstance = newSharedInstance;
}

// Used by unit tests to provide fake registration request objects
+ (void) setupRegistrationRequest:(OmniaPushAPNSRegistrationRequestOperation*)testRegistrationRequest {
    if (registrationRequest) return;
    if (testRegistrationRequest == nil) {
        registrationRequest = [[OmniaPushAPNSRegistrationRequestOperation alloc] initForRegistrationForRemoteNotificationTypes:UIRemoteNotificationTypeAlert application:application]; // TODO - accept notification type as argument
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

@end
