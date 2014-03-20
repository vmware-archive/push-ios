//
//  OmniaSpecHelper.mm
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-31.
//  Copyright (c) 2013 Pivotal. All rights reserved.
//

#import "Kiwi.h"

#import "OmniaSpecHelper.h"
#import "OmniaPushSDK.h"
#import "JRSwizzle.h"
#import "OmniaPushDebug.h"
#import "OmniaFakeOperationQueue.h"
#import "OmniaPushPersistentStorage.h"
#import "OmniaPushRegistrationParameters.h"

#import "OmniaPushAPNSRegistrationRequestOperation.h"

#define DELAY_TIME_IN_SECONDS  1
#define DELAY_TIME             (dispatch_time(DISPATCH_TIME_NOW, (int64_t)(DELAY_TIME_IN_SECONDS * NSEC_PER_SEC)))

#if !__has_feature(objc_arc)
#error This spec must be compiled with ARC to work properly
#endif

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
        [OmniaPushPersistentStorage reset];
    }
    return self;
}

- (void) reset
{
    self.params = nil;
    self.workerQueue = nil;
    self.apnsDeviceToken = nil;
    self.apnsDeviceToken2 = nil;
    self.backEndDeviceId = nil;
    self.backEndDeviceId2 = nil;
    self.application = nil;
}

#pragma mark - Application helpers

- (id) setupApplication
{
    self.application = [KWMock mockForClass:[UIApplication class]];
    [UIApplication stub:@selector(sharedApplication) andReturn:self.application];
    return self.application;
}

- (void) setupApplicationForSuccessfulRegistrationWithNotificationTypes:(UIRemoteNotificationType)notificationTypes
{
    [self setupApplicationForSuccessfulRegistrationWithNotificationTypes:notificationTypes
                                                  withNewApnsDeviceToken:self.apnsDeviceToken];
}

- (void) setupApplicationForSuccessfulRegistrationWithNotificationTypes:(UIRemoteNotificationType)notificationTypes
                                                 withNewApnsDeviceToken:(NSData *)newApnsDeviceToken
{
    [self.application stub:@selector(registerForRemoteNotificationTypes:) withBlock:^id(NSArray *params) {
        if ([self.applicationDelegate respondsToSelector:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:)]) {
            [(OmniaPushAPNSRegistrationRequestOperation *)self.applicationDelegate application:self.application didRegisterForRemoteNotificationsWithDeviceToken:newApnsDeviceToken];
        }
        return nil;
    }];
}

- (void) setupApplicationForFailedRegistrationWithNotificationTypes:(UIRemoteNotificationType)notificationTypes
                                                              error:(NSError *)error
{
    [self.application stub:@selector(registerForRemoteNotificationTypes:) withBlock:^id(NSArray *params) {
        if ([self.applicationDelegate respondsToSelector:@selector(application:didFailToRegisterForRemoteNotificationsWithError:)]) {
            [(OmniaPushAPNSRegistrationRequestOperation *)self.applicationDelegate application:self.application didFailToRegisterForRemoteNotificationsWithError:error];
        }
        return nil;
    }];
}

#pragma mark - App Delegate Helpers


- (id<UIApplicationDelegate>) setupApplicationDelegate
{
    id delegateMock = [KWMock mockForProtocol:@protocol(UIApplicationDelegate)];
    [delegateMock stub:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:) withArguments:self.application, nil, nil];
    self.applicationDelegate = delegateMock;
    [self.application stub:@selector(delegate) andReturn:self.applicationDelegate];
    [self.application stub:@selector(setDelegate:) withBlock:^id(NSArray *params) {
        if ([params[0] conformsToProtocol:@protocol(UIApplicationDelegate)]) {
            self.applicationDelegate = params[0];
        }
        return nil;
    }];
    return self.applicationDelegate;
}

- (void) setupApplicationDelegateForSuccessfulRegistration
{
    [self setupApplicationDelegateForSuccessfulRegistrationWithApnsDeviceToken:self.apnsDeviceToken];
}

- (void) setupApplicationDelegateForSuccessfulRegistrationWithApnsDeviceToken:(NSData *)apnsDeviceToken
{
    [(id)self.applicationDelegate stub:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:) withArguments:self.application, apnsDeviceToken, nil];
}

- (void) setupApplicationDelegateForFailedRegistrationWithError:(NSError *)error
{
    [(id)self.applicationDelegate stub:@selector(application:didFailToRegisterForRemoteNotificationsWithError:) withArguments:self.application, error, nil];
}

- (void) setupApplicationDelegateToReceiveNotification:(NSDictionary *)userInfo
{
    [(id)self.applicationDelegate stub:@selector(application:didReceiveRemoteNotification:) withArguments:self.application, userInfo, nil];
}

#pragma mark - Operation Queue helpers

- (OmniaFakeOperationQueue *) setupQueues
{
    self.workerQueue = [[OmniaFakeOperationQueue alloc] init];
    self.workerQueue.runSynchronously = YES;
    return self.workerQueue;
}

#pragma mark - Parameters helpers

- (OmniaPushRegistrationParameters *)setupParametersWithNotificationTypes:(UIRemoteNotificationType)notificationTypes
{
    self.params = [OmniaPushRegistrationParameters parametersForNotificationTypes:notificationTypes
                                                                       releaseUUID:TEST_RELEASE_UUID
                                                                     releaseSecret:TEST_RELEASE_SECRET
                                                                       deviceAlias:TEST_DEVICE_ALIAS];
    return self.params;
}

- (void) changeReleaseUuidInParameters:(NSString*)newReleaseUuid
{
    self.params = [OmniaPushRegistrationParameters parametersForNotificationTypes:self.params.remoteNotificationTypes
                                                                      releaseUUID:newReleaseUuid
                                                                    releaseSecret:self.params.releaseSecret
                                                                      deviceAlias:self.params.deviceAlias];
}

- (void) changeReleaseSecretInParameters:(NSString*)newReleaseSecret
{
    self.params = [OmniaPushRegistrationParameters parametersForNotificationTypes:self.params.remoteNotificationTypes
                                                                      releaseUUID:self.params.releaseUUID
                                                                    releaseSecret:newReleaseSecret
                                                                      deviceAlias:self.params.deviceAlias];
}

- (void) changeDeviceAliasInParameters:(NSString*)newDeviceAlias
{
    self.params = [OmniaPushRegistrationParameters parametersForNotificationTypes:self.params.remoteNotificationTypes
                                                                      releaseUUID:self.params.releaseUUID
                                                                    releaseSecret:self.params.releaseSecret
                                                                      deviceAlias:newDeviceAlias];
}

#pragma mark - NSURLConnection Helpers

- (BOOL) swizzleAsyncRequestWithSelector:(SEL)selector
                                   error:(NSError **)error
{
    return [NSURLConnection jr_swizzleClassMethod:@selector(sendAsynchronousRequest:queue:completionHandler:) withClassMethod:selector error:error];
}

@end
