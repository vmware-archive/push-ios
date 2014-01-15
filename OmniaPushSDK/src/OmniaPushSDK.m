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
#import "OmniaPushOperationQueueProvider.h"

// Global constant storage
NSString* const OmniaPushErrorDomain = @"OmniaPushErrorDomain";

// SDK instance variables
static NSOperationQueue *operationQueue = nil;
static OmniaPushSDK* sharedInstance = nil;
static dispatch_once_t once_token = 0;
static UIApplication *application = nil;

@interface OmniaPushSDK ()

@property (nonatomic, strong) id<UIApplicationDelegate> originalApplicationDelegate;
@property (nonatomic, strong) NSObject<OmniaPushAppDelegateProxy> *appDelegateProxy;

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
        
        OmniaPushAPNSRegistrationRequestOperation *op = [[OmniaPushAPNSRegistrationRequestOperation alloc] initForRegistrationForRemoteNotificationTypes:remoteNotificationTypes application:application];
        
        self.appDelegateProxy = [[OmniaPushAppDelegateProxyImpl alloc] initWithApplication:application originalApplicationDelegate:application.delegate registrationRequest:op];
        
        [self.appDelegateProxy registerForRemoteNotificationTypes:remoteNotificationTypes]; // TODO - should be an operation
        
        // TODO - start running the queue here if it's the real one
        // MAYBE - don't start running it here if it's the fake one since we want to drain it
        // outside and inspect the results
        // BETTER - simply start running it here either way so the same code works for both
        // testing and regular code.
    }
    return self;
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
    sharedInstance = newSharedInstance;
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
