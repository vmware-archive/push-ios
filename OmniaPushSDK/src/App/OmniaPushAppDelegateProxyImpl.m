//
//  OmniaPushAppDelegateProxy.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-18.
//  Copyright (c) 2013 Omnia. All rights reserved.
//

#import "OmniaPushAppDelegateProxyImpl.h"
#import "OmniaPushAPNSRegistrationRequest.h"
#import "OmniaPushDebug.h"
#import "OmniaPushRegistrationListener.h"

@interface OmniaPushAppDelegateProxyImpl ()

@property (atomic) BOOL isRegistrationCancelled;
@property (atomic) BOOL didRegistrationSucceed;
@property (atomic) BOOL didRegistrationFail;
@end

@implementation OmniaPushAppDelegateProxyImpl

- (instancetype) initWithAppDelegate:(NSObject<UIApplicationDelegate>*)appDelegate
                 registrationRequest:(NSObject<OmniaPushAPNSRegistrationRequest>*)registrationRequest
{
    // NOTE: no [super init] since there our super class, NSProxy, doesn't have any init method
    if (self) {
        if (appDelegate == nil) {
            [NSException raise:NSInvalidArgumentException format:@"appDelegate may not be nil"];
        }
        if (registrationRequest == nil) {
            [NSException raise:NSInvalidArgumentException format:@"registrationRequest may not be nil"];
        }
        self.appDelegate = appDelegate;
        self.registrationRequest = registrationRequest;
        self.listener = nil;
        self.isRegistrationCancelled = NO;
        self.didRegistrationFail = NO;
        self.didRegistrationSucceed = NO;
    }
    return self;
}

- (void) registerForRemoteNotificationTypes:(UIRemoteNotificationType)types
                                   listener:(id<OmniaPushRegistrationListener>)proxyListener
{
    self.listener = proxyListener;
    [self.registrationRequest registerForRemoteNotificationTypes:types];
}

- (void)application:(UIApplication*)app
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)devToken
{
    self.didRegistrationSucceed = YES;
    if (self.isRegistrationCancelled) return;
    
    OmniaPushLog(@"Registration with APNS successful. device token: %@", devToken);
    //const void *devTokenBytes = [devToken bytes];
    //[self sendProviderDeviceToken:devTokenBytes]; // custom method
    [self.appDelegate application:app didRegisterForRemoteNotificationsWithDeviceToken:devToken];
    if (self.listener) {
        [self.listener application:app didRegisterForRemoteNotificationsWithDeviceToken:devToken];
    }
    // TODO - save the registration somehow
}

// TODO - decide if we even need this method - probably not.
- (void)application:(UIApplication *)app
    didFailToRegisterForRemoteNotificationsWithError:(NSError*)err
{
    self.didRegistrationFail = YES;
    if (self.isRegistrationCancelled) return;

    OmniaPushLog(@"Error in registration with APNS. Error: %@", err);
    [self.appDelegate application:app didFailToRegisterForRemoteNotificationsWithError:err];
    if (self.listener) {
        [self.listener application:app didFailToRegisterForRemoteNotificationsWithError:err];
    }
    // TODO - handle the error somehow
}

- (void) application:(UIApplication*)application
    didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    OmniaPushLog(@"didReceiveRemoteNotification: %@", userInfo);
    // TODO - do something here?
}

- (NSMethodSignature*) methodSignatureForSelector:(SEL)sel
{
    return [self.appDelegate methodSignatureForSelector:sel];
}

- (void) forwardInvocation:(NSInvocation*)invocation
{
    // TODO - do I need to capture my own delegate methods above?
    [invocation setTarget:self.appDelegate];
    [invocation invoke];
}

- (void) cancelRegistration
{
    self.isRegistrationCancelled = YES;
}

@end
