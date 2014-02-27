//
//  OmniaSpecHelper.mm
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-31.
//  Copyright (c) 2013 Pivotal. All rights reserved.
//

#import "OmniaSpecHelper.h"
#import "OmniaPushSDK.h"
#import "OmniaPushAPNSRegistrationRequestOperation.h"
#import "OmniaPushAppDelegateProxy.h"
#import "OmniaPushDebug.h"
#import "OmniaFakeOperationQueue.h"
#import "OmniaPushOperationQueueProvider.h"
#import "OmniaPushApplicationDelegateSwitcherProvider.h"
#import "OmniaPushFakeApplicationDelegateSwitcher.h"
#import "OmniaPushPersistentStorage.h"
#import "OmniaPushRegistrationParameters.h"
#import "OmniaPushRegistrationEngine.h"
#import "OmniaPushFakeNSURLConnectionFactory.h"
#import "OmniaPushNSURLConnectionProvider.h"

#define DELAY_TIME_IN_SECONDS  1
#define DELAY_TIME             (dispatch_time(DISPATCH_TIME_NOW, (int64_t)(DELAY_TIME_IN_SECONDS * NSEC_PER_SEC)))

#if !__has_feature(objc_arc)
#error This spec must be compiled with ARC to work properly
#endif

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

NSInteger TEST_NOTIFICATION_TYPES = UIRemoteNotificationTypeAlert;

NSString *const TEST_RELEASE_UUID     = @"444-555-666-777";
NSString *const TEST_RELEASE_SECRET   = @"No secret is as strong as its blabbiest keeper";
NSString *const TEST_DEVICE_ALIAS     = @"Let's watch cat videos";
NSString *const TEST_RELEASE_UUID_2   = @"222-444-999-ZZZ";
NSString *const TEST_RELEASE_SECRET_2 = @"My cat's breath smells like cat food";
NSString *const TEST_DEVICE_ALIAS_2   = @"I can haz cheezburger?";

@implementation OmniaSpecHelper

# pragma mark - Spec Helper lifecycle

- (instancetype) init
{
    self = [super init];
    if (self) {
        self.apnsDeviceToken = [@"TEST DEVICE TOKEN 1" dataUsingEncoding:NSUTF8StringEncoding];
        self.apnsDeviceToken2 = [@"TEST DEVICE TOKEN 2" dataUsingEncoding:NSUTF8StringEncoding];
        self.backEndDeviceId = @"BACK END DEVICE ID 1";
        self.backEndDeviceId2 = @"BACK END DEVICE ID 2";
        self.application = [UIApplication sharedApplication];
        self.storage = [[OmniaPushPersistentStorage alloc] init];
        [self.storage reset];
    }
    return self;
}

- (void) reset
{
    self.registrationEngine = nil;
    self.params = nil;
    self.workerQueue = nil;
    [OmniaPushOperationQueueProvider setWorkerQueue:nil];
    self.apnsDeviceToken = nil;
    self.apnsDeviceToken2 = nil;
    self.backEndDeviceId = nil;
    self.backEndDeviceId2 = nil;
    self.application = nil;
    self.applicationDelegate = nil;
    self.registrationRequestOperation = nil;
    if (self.applicationDelegateProxy && [self.applicationDelegateProxy isKindOfClass:[OmniaPushAppDelegateProxy class]]) {
        [self.applicationDelegateProxy cleanup];
    }
    self.applicationDelegateProxy = nil;
    self.applicationDelegateSwitcher = nil;
    self.storage = nil;
    self.connectionFactory = nil;
    [OmniaPushApplicationDelegateSwitcherProvider setSwitcher:nil];
    [OmniaPushNSURLConnectionProvider setFactory:nil];
}

#pragma mark - Application helpers

- (id) setupApplication
{
    self.application = fake_for([UIApplication class]);
    return self.application;
}

- (void) setupApplicationForSuccessfulRegistrationWithNotificationTypes:(UIRemoteNotificationType)notificationTypes
{
    [self setupApplicationForSuccessfulRegistrationWithNotificationTypes:notificationTypes withNewApnsDeviceToken:self.apnsDeviceToken];
}

- (void) setupApplicationForSuccessfulRegistrationWithNotificationTypes:(UIRemoteNotificationType)notificationTypes
                                                 withNewApnsDeviceToken:(NSData*)newApnsDeviceToken
{
    self.application stub_method("registerForRemoteNotificationTypes:").with(notificationTypes).and_do(^(NSInvocation*) {
        [[self currentApplicationDelegate] application:self.application didRegisterForRemoteNotificationsWithDeviceToken:newApnsDeviceToken];
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
    [self setupApplicationDelegateForSuccessfulRegistrationWithApnsDeviceToken:self.apnsDeviceToken];
}

- (void) setupApplicationDelegateForSuccessfulRegistrationWithApnsDeviceToken:(NSData*)apnsDeviceToken
{
    self.applicationDelegate stub_method("application:didRegisterForRemoteNotificationsWithDeviceToken:").with(self.application, apnsDeviceToken);
}

- (void) setupApplicationDelegateForFailedRegistrationWithError:(NSError*)error
{
    self.applicationDelegate stub_method("application:didFailToRegisterForRemoteNotificationsWithError:").with(self.application, error);
}

- (void) setupApplicationDelegateToReceiveNotification:(NSDictionary*)userInfo
{
    self.applicationDelegate stub_method("application:didReceiveRemoteNotification:").with(self.application, userInfo);
}

#pragma mark - Application Delegate Proxy helpers

- (OmniaPushAppDelegateProxy*) setupAppDelegateProxy
{
    self.applicationDelegateProxy = [[OmniaPushAppDelegateProxy alloc] initWithApplication:self.application originalApplicationDelegate:self.applicationDelegate registrationEngine:self.registrationEngine];
    return self.applicationDelegateProxy;
}

#pragma mark - Registration Request helpers

- (OmniaPushAPNSRegistrationRequestOperation*) setupRegistrationRequestOperationWithNotificationTypes:(UIRemoteNotificationType)notificationTypes
{
    self.registrationRequestOperation = [[OmniaPushAPNSRegistrationRequestOperation alloc] initWithParameters:self.params application:self.application];
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

#pragma mark - Parameters helpers

- (OmniaPushRegistrationParameters*) setupParametersWithNotificationTypes:(UIRemoteNotificationType)notificationTypes
{
    self.params = [[OmniaPushRegistrationParameters alloc] initForNotificationTypes:notificationTypes
                                                                        releaseUuid:TEST_RELEASE_UUID
                                                                      releaseSecret:TEST_RELEASE_SECRET
                                                                        deviceAlias:TEST_DEVICE_ALIAS];
    return self.params;
}

- (void) changeReleaseUuidInParameters:(NSString*)newReleaseUuid
{
    self.params = [[OmniaPushRegistrationParameters alloc] initForNotificationTypes:self.params.remoteNotificationTypes
                                                                       releaseUuid:newReleaseUuid
                                                                     releaseSecret:self.params.releaseSecret
                                                                        deviceAlias:self.params.deviceAlias];
}

- (void) changeReleaseSecretInParameters:(NSString*)newReleaseSecret
{
    self.params = [[OmniaPushRegistrationParameters alloc] initForNotificationTypes:self.params.remoteNotificationTypes
                                                                        releaseUuid:self.params.releaseUuid
                                                                      releaseSecret:newReleaseSecret
                                                                        deviceAlias:self.params.deviceAlias];
}

- (void) changeDeviceAliasInParameters:(NSString*)newDeviceAlias
{
    self.params = [[OmniaPushRegistrationParameters alloc] initForNotificationTypes:self.params.remoteNotificationTypes
                                                                        releaseUuid:self.params.releaseUuid
                                                                      releaseSecret:self.params.releaseSecret
                                                                        deviceAlias:newDeviceAlias];
}


#pragma mark - Registration Engine helpers

- (OmniaPushRegistrationEngine*) setupRegistrationEngine
{
    self.registrationEngine = [[OmniaPushRegistrationEngine alloc] initWithApplication:self.application originalApplicationDelegate:self.applicationDelegate listener:nil];
    return self.registrationEngine;
}

#pragma mark - NSURLConnection heleprs

- (OmniaPushFakeNSURLConnectionFactory*) setupConnectionFactory
{
    self.connectionFactory = [[OmniaPushFakeNSURLConnectionFactory alloc] init];
    [OmniaPushNSURLConnectionProvider setFactory:self.connectionFactory];
    return self.connectionFactory;
}

@end
