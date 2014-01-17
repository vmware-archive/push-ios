//
//  OmniaSpecHelper.mm
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-31.
//  Copyright (c) 2013 Omnia. All rights reserved.
//

#import "OmniaSpecHelper.h"
#import "OmniaPushSDK.h"
#import "OmniaPushAPNSRegistrationRequestOperation.h"
#import "OmniaPushAppDelegateProxy.h"
#import "OmniaPushAppDelegateProxyImpl.h"
#import "OmniaPushDebug.h"
#import "OmniaFakeOperationQueue.h"
#import "OmniaPushOperationQueueProvider.h"
#import "OmniaPushApplicationDelegateSwitcherProvider.h"
#import "OmniaPushFakeApplicationDelegateSwitcher.h"

#define DELAY_TIME_IN_SECONDS  1
#define DELAY_TIME             (dispatch_time(DISPATCH_TIME_NOW, (int64_t)(DELAY_TIME_IN_SECONDS * NSEC_PER_SEC)))

#if !__has_feature(objc_arc)
#error This spec must be compiled with ARC to work properly
#endif

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

@implementation OmniaSpecHelper

# pragma mark - Spec Helper lifecycle

- (instancetype) init
{
    self = [super init];
    if (self) {
        self.deviceToken = [@"TEST DEVICE TOKEN" dataUsingEncoding:NSUTF8StringEncoding];
        self.application = [UIApplication sharedApplication];
    }
    return self;
}

- (void) reset
{
    self.workerQueue = nil;
    [OmniaPushOperationQueueProvider setWorkerQueue:nil];
    self.deviceToken = nil;
    self.application = nil;
    self.applicationDelegate = nil;
    self.registrationRequestOperation = nil;
    if (self.applicationDelegateProxy && [self.applicationDelegateProxy isKindOfClass:[OmniaPushAppDelegateProxyImpl class]]) {
        [self.applicationDelegateProxy cleanup];
    }
    self.applicationDelegateProxy = nil;
    self.applicationDelegateSwitcher = nil;
    [OmniaPushApplicationDelegateSwitcherProvider setSwitcher:nil];
}

#pragma mark - Application helpers

- (id) setupApplication
{
    self.application = fake_for([UIApplication class]);
    return self.application;
}

- (void) setupApplicationForSuccessfulRegistrationWithNotificationTypes:(UIRemoteNotificationType)notificationTypes
{
    self.application stub_method("registerForRemoteNotificationTypes:").with(notificationTypes).and_do(^(NSInvocation*) {
        [[self currentApplicationDelegate] application:self.application didRegisterForRemoteNotificationsWithDeviceToken:self.deviceToken];
    });
}

- (void) setupApplicationForFailedRegistrationWithNotificationTypes:(UIRemoteNotificationType)notificationTypes error:(NSError *)error
{
    self.application stub_method("registerForRemoteNotificationTypes:").with(notificationTypes).and_do(^(NSInvocation*) {
        [[self currentApplicationDelegate] application:self.application didFailToRegisterForRemoteNotificationsWithError:error];
    });
}

#pragma mark - App Delegate Helpers

- (id<UIApplicationDelegate>) currentApplicationDelegate
{
    if (self.applicationDelegateProxy) {
        return self.applicationDelegateProxy;
    } else {
        return self.applicationDelegate;
    }
}

- (id<UIApplicationDelegate>) setupApplicationDelegate
{
    self.applicationDelegateSwitcher = [[OmniaPushFakeApplicationDelegateSwitcher alloc] initWithSpecHelper:self];
    [OmniaPushApplicationDelegateSwitcherProvider setSwitcher:self.applicationDelegateSwitcher];
    self.applicationDelegate = fake_for(@protocol(UIApplicationDelegate));
    self.application stub_method("delegate").and_do(^(NSInvocation *invocation) {
        id<UIApplicationDelegate> d = [self currentApplicationDelegate];
        [invocation setReturnValue:&d];
    });
    return self.applicationDelegate;
}

- (void) setupApplicationDelegateForSuccessfulRegistration
{
    self.applicationDelegate stub_method("application:didRegisterForRemoteNotificationsWithDeviceToken:").with(self.application, self.deviceToken);
}

- (void) setupApplicationDelegateForFailedRegistrationWithError:(NSError*)error
{
    self.applicationDelegate stub_method("application:didFailToRegisterForRemoteNotificationsWithError:").with(self.application, error);
}

#pragma mark - Registration Request helpers

- (OmniaPushAPNSRegistrationRequestOperation*) setupRegistrationRequestOperationWithNotificationTypes:(UIRemoteNotificationType)notificationTypes
{
    self.registrationRequestOperation = [[OmniaPushAPNSRegistrationRequestOperation alloc] initForRegistrationForRemoteNotificationTypes:notificationTypes application:self.application];
    return self.registrationRequestOperation;
}

#pragma mark - Front-end singleton helpers

- (void) resetSingleton
{
    SEL setSharedInstanceSelector = sel_registerName("setSharedInstance:");
    [OmniaPushSDK performSelector:setSharedInstanceSelector withObject:nil];
}

- (void) setApplicationInSingleton
{
    SEL setupApplicationSelector = sel_registerName("setupApplication:");
    [OmniaPushSDK performSelector:setupApplicationSelector withObject:self.application];
}

#pragma mark - Operation Queue helpers

- (OmniaFakeOperationQueue*) setupQueues
{
    self.workerQueue = [[OmniaFakeOperationQueue alloc] init];
    [OmniaPushOperationQueueProvider setWorkerQueue:self.workerQueue];
    [OmniaPushOperationQueueProvider setMainQueue:self.workerQueue];
    return self.workerQueue;
}

// TODO - need a method to drain operation queue

@end