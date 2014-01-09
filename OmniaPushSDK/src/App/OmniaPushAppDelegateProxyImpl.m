//
//  OmniaPushAppDelegateProxy.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-18.
//  Copyright (c) 2013 Omnia. All rights reserved.
//

#import "OmniaPushAppDelegateProxyImpl.h"
#import "OmniaPushAPNSRegistrationRequestOperation.h"
#import "OmniaPushDebug.h"
#import "OmniaPushRegistrationListener.h"
#import "OmniaPushOperationQueueProvider.h"
#import "OmniaPushRegistrationCompleteOperation.h"
#import "OmniaPushRegistrationFailedOperation.h"

@interface OmniaPushAppDelegateProxyImpl ()

@property (atomic) BOOL isRegistrationCancelled;
@property (atomic) BOOL didRegistrationSucceed;
@property (atomic) BOOL didRegistrationFail;
@end

@implementation OmniaPushAppDelegateProxyImpl

- (instancetype) initWithAppDelegate:(NSObject<UIApplicationDelegate>*)appDelegate
                 registrationRequest:(OmniaPushAPNSRegistrationRequestOperation*)registrationRequest
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
    
    [[OmniaPushOperationQueueProvider operationQueue] addOperation:self.registrationRequest];
}

- (void)application:(UIApplication*)app
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)devToken
{
    self.didRegistrationSucceed = YES;
    if (self.isRegistrationCancelled) return;

    OmniaPushRegistrationCompleteOperation *op = [[OmniaPushRegistrationCompleteOperation alloc] initWithApplication:app applicationDelegate:self.appDelegate listener:self.listener deviceToken:devToken];
    
    [[OmniaPushOperationQueueProvider operationQueue] addOperation:op];
}

// TODO - decide if we even need this method - probably not.
- (void)application:(UIApplication *)app
    didFailToRegisterForRemoteNotificationsWithError:(NSError*)err
{
    self.didRegistrationFail = YES;
    if (self.isRegistrationCancelled) return;

    OmniaPushRegistrationFailedOperation *op = [[OmniaPushRegistrationFailedOperation alloc] init];

    [[OmniaPushOperationQueueProvider operationQueue] addOperation:op];
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
