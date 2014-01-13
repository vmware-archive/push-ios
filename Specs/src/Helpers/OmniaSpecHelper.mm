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
#import "OmniaPushRegistrationListener.h"
#import "OmniaPushDebug.h"
#import "OmniaFakeOperationQueue.h"
#import "OmniaPushOperationQueueProvider.h"

#define DELAY_TIME_IN_SECONDS  1
#define DELAY_TIME             (dispatch_time(DISPATCH_TIME_NOW, (int64_t)(DELAY_TIME_IN_SECONDS * NSEC_PER_SEC)))

#if !__has_feature(objc_arc)
#error This spec must be compiled with ARC to work properly
#endif

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

@interface OmniaSpecHelper ()

@property (nonatomic) NSData *deviceToken;

@end

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
    self.operationQueue = nil;
    [OmniaPushOperationQueueProvider setOperationQueue:nil];
    self.deviceToken = nil;
    self.application = nil;
    self.applicationDelegate = nil;
    self.registrationRequestOperation = nil;
    self.applicationDelegateProxy = nil;
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
        if (self.applicationDelegateProxy) {
            [self.applicationDelegateProxy application:self.application didRegisterForRemoteNotificationsWithDeviceToken:self.deviceToken];
        } else {
            [self.applicationDelegate application:self.application didRegisterForRemoteNotificationsWithDeviceToken:self.deviceToken];
        }
    });
}

- (void) setupApplicationForFailedRegistrationWithNotificationTypes:(UIRemoteNotificationType)notificationTypes error:(NSError *)error
{
    self.application stub_method("registerForRemoteNotificationTypes:").with(notificationTypes).and_do(^(NSInvocation*) {
        if (self.applicationDelegateProxy) {
            [self.applicationDelegateProxy application:self.application didFailToRegisterForRemoteNotificationsWithError:error];
        } else {
            [self.applicationDelegate application:self.application didFailToRegisterForRemoteNotificationsWithError:error];
        }
    });
}

#pragma mark - App Delegate Helpers

- (id<UIApplicationDelegate>) setupApplicationDelegate
{
    self.applicationDelegate = fake_for(@protocol(UIApplicationDelegate));
    self.application stub_method("delegate").and_return(self.applicationDelegate);
    self.application stub_method("setDelegate:").with(Arguments::anything);
    return self.applicationDelegate;
}

- (void) setupApplicationDelegateForSuccessfulRegistration
{
    self.applicationDelegate stub_method("application:didRegisterForRemoteNotificationsWithDeviceToken:").with(self.application, self.deviceToken);;
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

//void setupRegistrationRequestOperationForSuccessfulRegistration(NSProxy<OmniaPushAppDelegateProxy> *appDelegateProxy) {
//    registrationRequestOperation stub_method("registerForRemoteNotificationTypes:").with(TEST_NOTIFICATION_TYPE).and_do(^(NSInvocation*) {
//        [appDelegateProxy application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
//    });
//}

//void setupRegistrationRequestOperationForFailedRegistration(NSProxy<OmniaPushAppDelegateProxy> *appDelegateProxy, NSError *error) {
//    registrationRequestOperation stub_method("registerForRemoteNotificationTypes:").with(TEST_NOTIFICATION_TYPE).and_do(^(NSInvocation*) {
//        [appDelegateProxy application:application didFailToRegisterForRemoteNotificationsWithError:error];
//    });
//}

//void setupRegistrationRequestOperationForSuccessfulAsynchronousRegistration(NSProxy<OmniaPushAppDelegateProxy> *appDelegateProxy, int delayInMilliseconds) {
//    registrationRequestOperation stub_method("registerForRemoteNotificationTypes:").with(TEST_NOTIFICATION_TYPE).and_do(^(NSInvocation*) {
//        dispatch_time_t dispatchTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInMilliseconds) * NSEC_PER_MSEC);
//        dispatch_after(dispatchTime, backgroundQueue, ^(void) {
//            [appDelegateProxy application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
//        });
//    });
//}

//void setupRegistrationRequestOperationForFailedAsynchronousRegistration(NSProxy<OmniaPushAppDelegateProxy> *appDelegateProxy, NSError *error, int delayInMilliseconds) {
//    registrationRequestOperation stub_method("registerForRemoteNotificationTypes:").with(TEST_NOTIFICATION_TYPE).and_do(^(NSInvocation*) {
//        dispatch_time_t dispatchTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInMilliseconds) * NSEC_PER_MSEC);
//        dispatch_after(dispatchTime, backgroundQueue, ^(void) {
//            [appDelegateProxy application:application didFailToRegisterForRemoteNotificationsWithError:error];
//        });
//    });
//}

//void setupRegistrationRequestOperationForTimeout(NSProxy<OmniaPushAppDelegateProxy> *appDelegateProxy) {
//    // doesn't invoke callback so the semaphore times out instead
//    registrationRequestOperation stub_method("registerForRemoteNotificationTypes:").with(TEST_NOTIFICATION_TYPE);
//}

#pragma mark - Front-end singleton helpers

//- (void) setRegistrationRequestInSingleton
//{
//    SEL setupRegistrationRequestSelector = sel_registerName("setupRegistrationRequest:");
//    [OmniaPushSDK performSelector:setupRegistrationRequestSelector withObject:self.registrationRequestOperation];
//}
//
//- (void) setApplicationInSingleton
//{
//    SEL setupApplicationSelector = sel_registerName("setupApplication:");
//    [OmniaPushSDK performSelector:setupApplicationSelector withObject:self.application];
//}
//
//- (void) setAppDelegateProxyInSingleton
//{
//    SEL setupAppDelegateProxySelector = sel_registerName("setupAppDelegateProxy:");
//    [OmniaPushSDK performSelector:setupAppDelegateProxySelector withObject:self.applicationDelegateProxy];
//}

#pragma mark - Operation Queue helpers

- (OmniaFakeOperationQueue*) setupOperationQueue
{
    self.operationQueue = [[OmniaFakeOperationQueue alloc] init];
    [OmniaPushOperationQueueProvider setOperationQueue:self.operationQueue];
    return self.operationQueue;
}

// TODO - need a method to drain operation queue

@end