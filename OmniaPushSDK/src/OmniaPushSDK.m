//
//  OmniaPushSDK.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-31.
//  Copyright (c) 2013 Omnia. All rights reserved.
//

#import "OmniaPushSDK.h"
#import "OmniaPushAPNSRegistrationRequestOperation.h"
#import "OmniaPushAppDelegateProxy.h"
#import "OmniaPushOperationQueueProvider.h"
#import "OmniaPushApplicationDelegateSwitcher.h"
#import "OmniaPushApplicationDelegateSwitcherProvider.h"
#import "OmniaPushRegistrationEngine.h"

// Global constant storage
NSString* const OmniaPushErrorDomain = @"OmniaPushErrorDomain";

// SDK instance variables
static OmniaPushSDK* sharedInstance = nil;
static dispatch_once_t once_token = 0;
static UIApplication *application = nil;

@interface OmniaPushSDK ()

@property (nonatomic, strong) id<UIApplicationDelegate> originalApplicationDelegate;
@property (nonatomic, strong) OmniaPushAppDelegateProxy *appDelegateProxy;

@end

@implementation OmniaPushSDK

+ (OmniaPushSDK*) registerWithParameters:(OmniaPushRegistrationParameters*)parameters
{
    return [OmniaPushSDK registerWithParameters:parameters listener:nil];
}

// NOTE:  the application delegate will still be called after registration completes, except if the
// registration attempt times out.  The listener will be regardless if the registration succeeds, fails,
// or times out.  The default time out interval is 60 seconds.

+ (OmniaPushSDK*) registerWithParameters:(OmniaPushRegistrationParameters*)parameters
                                            listener:(id<OmniaPushRegistrationListener>)listener
{
    if (parameters == nil) {
        [NSException raise:NSInvalidArgumentException format:@"parameters may not be nil"];
    }
    
    dispatch_once(&once_token, ^{
        if (sharedInstance == nil) {
            sharedInstance = [[OmniaPushSDK alloc] initWithParameters:parameters listener:listener];
        }
    });
    return sharedInstance;
}

- (instancetype) initWithParameters:(OmniaPushRegistrationParameters*)parameters
                           listener:(id<OmniaPushRegistrationListener>)listener
{
    self = [super init];
    if (self) {
        [OmniaPushSDK setupApplication:nil];
        
        OmniaPushRegistrationEngine *engine = [[OmniaPushRegistrationEngine alloc] initWithApplication:application];
        
        self.appDelegateProxy = [[OmniaPushAppDelegateProxy alloc] initWithApplication:application originalApplicationDelegate:application.delegate registrationEngine:engine];
        
        [self.appDelegateProxy registerWithParameters:parameters]; // TODO - should be an operation
        
        // TODO - start running the queue here if it's the real one
        // MAYBE - don't start running it here if it's the fake one since we want to drain it
        // outside and inspect the results
        // BETTER - simply start running it here either way so the same code works for both
        // testing and regular code.
//        NSOperationQueue *queue = [OmniaPushOperationQueueProvider workerQueue];
//        queue.suspended = NO;
    }
    return self;
}

- (void) cleanupInstance
{
    @synchronized(self) {
        if (self.appDelegateProxy) {
            [self.appDelegateProxy cleanup];
        }
        self.appDelegateProxy = nil;
        self.originalApplicationDelegate = nil;
    }
}

+ (void) teardown
{
    // NOTE - may be called multiple times during unit tests
    if (sharedInstance) {
        [sharedInstance cleanupInstance];
        sharedInstance = nil;
    }
    once_token = 0;
    application = nil;
}

#pragma mark - Unit test helpers

// Used by unit tests to provide a fake singleton or to reset this singleton for following tests
+ (void) setSharedInstance:(OmniaPushSDK*)newSharedInstance {
    [OmniaPushSDK teardown];
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
