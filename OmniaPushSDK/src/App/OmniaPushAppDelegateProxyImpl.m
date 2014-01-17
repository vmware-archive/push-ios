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
#import "OmniaPushOperationQueueProvider.h"
#import "OmniaPushRegistrationCompleteOperation.h"
#import "OmniaPushRegistrationFailedOperation.h"
#import "OmniaPushApplicationDelegateSwitcherProvider.h"
#import "OmniaPushApplicationDelegateSwitcher.h"

@interface OmniaPushAppDelegateProxyImpl ()

@property (nonatomic) UIApplication *application;
@property (nonatomic) NSObject<UIApplicationDelegate> *originalApplicationDelegate;

@end

@implementation OmniaPushAppDelegateProxyImpl

- (instancetype) initWithApplication:(UIApplication*)application
         originalApplicationDelegate:(NSObject<UIApplicationDelegate>*)originalApplicationDelegate
{
    if (self = [super init]) {
        if (application == nil) {
            [NSException raise:NSInvalidArgumentException format:@"application may not be nil"];
        }
        if (originalApplicationDelegate == nil) {
            [NSException raise:NSInvalidArgumentException format:@"originalApplicationDelegate may not be nil"];
        }
        self.application = application;
        self.originalApplicationDelegate = originalApplicationDelegate;
        [self replaceApplicationDelegate];
    }
    return self;
}

- (void) cleanup
{
    if (self.application && self.originalApplicationDelegate) {
        [self restoreApplicationDelegate];
    }
    self.application = nil;
    self.originalApplicationDelegate = nil;
}

- (void) replaceApplicationDelegate
{
    [[self getApplicationDelegateSwitcher] switchApplicationDelegate:self inApplication:self.application];
}

- (void) restoreApplicationDelegate
{
    [[self getApplicationDelegateSwitcher] switchApplicationDelegate:self.originalApplicationDelegate inApplication:self.application];
}

- (NSObject<OmniaPushApplicationDelegateSwitcher>*) getApplicationDelegateSwitcher
{
    return [OmniaPushApplicationDelegateSwitcherProvider switcher];
}

- (void) registerForRemoteNotificationTypes:(UIRemoteNotificationType)types
{
    OmniaPushAPNSRegistrationRequestOperation *op = [[OmniaPushAPNSRegistrationRequestOperation alloc] initForRegistrationForRemoteNotificationTypes:types application:self.application];
    [[OmniaPushOperationQueueProvider workerQueue] addOperation:op];
}

- (void)application:(UIApplication*)app
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)devToken
{
    OmniaPushRegistrationCompleteOperation *op = [[OmniaPushRegistrationCompleteOperation alloc] initWithApplication:app applicationDelegate:self.originalApplicationDelegate deviceToken:devToken];
    [[OmniaPushOperationQueueProvider workerQueue] addOperation:op];
}

- (void)application:(UIApplication *)app
    didFailToRegisterForRemoteNotificationsWithError:(NSError*)err
{
    OmniaPushRegistrationFailedOperation *op = [[OmniaPushRegistrationFailedOperation alloc] initWithApplication:app applicationDelegate:self.originalApplicationDelegate error:err];
    [[OmniaPushOperationQueueProvider workerQueue] addOperation:op];
}

- (NSMethodSignature*) methodSignatureForSelector:(SEL)sel
{
    return [self.originalApplicationDelegate methodSignatureForSelector:sel];
}

- (void) forwardInvocation:(NSInvocation*)invocation
{
    [invocation setTarget:self.originalApplicationDelegate];
    [invocation invoke];
}

@end
