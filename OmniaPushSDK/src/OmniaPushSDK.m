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
static NSObject<UIApplicationDelegate> *originalApplicationDelegate;

// Something seems to dealloc the original application delegate in the demo app between individual instances of the
// SDK unless we keep a static reference to it above.  I think it's safe to leak the original application delegate
// since there should usually be only one during most applications.  The demo app is an exception, but it's a test
// app that is not intended to be released to production.

@interface OmniaPushSDK ()

@property (nonatomic, strong) OmniaPushAppDelegateProxy *appDelegateProxy;
@property (nonatomic, strong) OmniaPushRegistrationEngine *registrationEngine;

@end

@implementation OmniaPushSDK

+ (OmniaPushSDK*) registerWithParameters:(OmniaPushRegistrationParameters*)parameters
{
    return [OmniaPushSDK registerWithParameters:parameters listener:nil];
}

// NOTE:  the application delegate will still be called after APNS registration completes, except if the
// registration attempt times out.  The listener will be called after both APNS registration and registration
// with the back-end Omnia server compeltes of fails.  Time-outs with APNS registration are not detected.  Time-outs
// with the Omnia server are detected after 60 seconds.

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
        originalApplicationDelegate = application.delegate;
        
        self.registrationEngine = [[OmniaPushRegistrationEngine alloc] initWithApplication:application
                                                               originalApplicationDelegate:application.delegate
                                                                                  listener:listener];
        
        self.appDelegateProxy = [[OmniaPushAppDelegateProxy alloc] initWithApplication:application
                                                           originalApplicationDelegate:application.delegate
                                                                    registrationEngine:self.registrationEngine];
        
        [self.registrationEngine startRegistration:parameters];
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
        self.registrationEngine = nil;
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
+ (void) setSharedInstance:(OmniaPushSDK*)newSharedInstance
{
    [OmniaPushSDK teardown];
    sharedInstance = newSharedInstance;
}

// Used by unit tests to provide fake application objects
+ (void) setupApplication:(UIApplication*)testApplication
{
    if (application) {
        return;
    }
    
    if (testApplication == nil) {
        application = [UIApplication sharedApplication];
    } else {
        application = testApplication;
    }
}

@end
