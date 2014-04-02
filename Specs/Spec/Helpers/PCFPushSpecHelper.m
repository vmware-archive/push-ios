//
//  PCFPushSpecHelper.mm
//  PCFPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-31.
//  Copyright (c) 2013 Pivotal. All rights reserved.
//

#import "Kiwi.h"

#import "PCFPushSpecHelper.h"
#import "PCFPushAppDelegate.h"
#import "PCFPushSDK.h"
#import "JRSwizzle.h"
#import "PCFPushDebug.h"
#import "PCFPushPersistentStorage.h"
#import "PCFPushParameters.h"

#if !__has_feature(objc_arc)
#error This spec must be compiled with ARC to work properly
#endif

NSInteger TEST_NOTIFICATION_TYPES = UIRemoteNotificationTypeAlert;

NSString *const TEST_VARIANT_UUID_1   = @"444-555-666-777";
NSString *const TEST_RELEASE_SECRET_1 = @"No secret is as strong as its blabbiest keeper";
NSString *const TEST_DEVICE_ALIAS_1   = @"Let's watch cat videos";
NSString *const TEST_VARIANT_UUID_2   = @"222-444-999-ZZZ";
NSString *const TEST_RELEASE_SECRET_2 = @"My cat's breath smells like cat food";
NSString *const TEST_DEVICE_ALIAS_2   = @"I can haz cheezburger?";

@implementation PCFPushSpecHelper

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
        [PCFPushPersistentStorage reset];
    }
    return self;
}

- (void) reset
{
    self.params = nil;
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
            [(PCFPushAppDelegate *)self.applicationDelegate application:self.application
                             didRegisterForRemoteNotificationsWithDeviceToken:newApnsDeviceToken];
        }
        return nil;
    }];
}

- (void) setupApplicationForFailedRegistrationWithNotificationTypes:(UIRemoteNotificationType)notificationTypes
                                                              error:(NSError *)error
{
    [self.application stub:@selector(registerForRemoteNotificationTypes:) withBlock:^id(NSArray *params) {
        if ([self.applicationDelegate respondsToSelector:@selector(application:didFailToRegisterForRemoteNotificationsWithError:)]) {
            [(PCFPushAppDelegate *)self.applicationDelegate application:self.application
                             didFailToRegisterForRemoteNotificationsWithError:error];
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

#pragma mark - Parameters helpers

- (PCFPushParameters *)setupParametersWithNotificationTypes:(UIRemoteNotificationType)notificationTypes
{
    self.params = [PCFPushParameters parametersWithNotificationTypes:notificationTypes
                                                                       variantUUID:TEST_VARIANT_UUID_1
                                                                     releaseSecret:TEST_RELEASE_SECRET_1
                                                                       deviceAlias:TEST_DEVICE_ALIAS_1];
    return self.params;
}

- (void) changeVariantUUIDInParameters:(NSString*)newVariantUUID
{
    self.params = [PCFPushParameters parametersWithNotificationTypes:self.params.remoteNotificationTypes
                                                                      variantUUID:newVariantUUID
                                                                    releaseSecret:self.params.releaseSecret
                                                                      deviceAlias:self.params.deviceAlias];
}

- (void) changeReleaseSecretInParameters:(NSString*)newReleaseSecret
{
    self.params = [PCFPushParameters parametersWithNotificationTypes:self.params.remoteNotificationTypes
                                                                      variantUUID:self.params.variantUUID
                                                                    releaseSecret:newReleaseSecret
                                                                      deviceAlias:self.params.deviceAlias];
}

- (void) changeDeviceAliasInParameters:(NSString*)newDeviceAlias
{
    self.params = [PCFPushParameters parametersWithNotificationTypes:self.params.remoteNotificationTypes
                                                                      variantUUID:self.params.variantUUID
                                                                    releaseSecret:self.params.releaseSecret
                                                                      deviceAlias:newDeviceAlias];
}

- (void)setupDefaultSavedParameters
{
    [PCFPushPersistentStorage setReleaseSecret:TEST_RELEASE_SECRET_1];
    [PCFPushPersistentStorage setVariantUUID:TEST_VARIANT_UUID_1];
    [PCFPushPersistentStorage setDeviceAlias:TEST_DEVICE_ALIAS_1];
    [PCFPushPersistentStorage setAPNSDeviceToken:self.apnsDeviceToken];
    [PCFPushPersistentStorage setBackEndDeviceID:self.backEndDeviceId];
}

#pragma mark - NSURLConnection Helpers

- (BOOL) swizzleAsyncRequestWithSelector:(SEL)selector
                                   error:(NSError **)error
{
    return [NSURLConnection jr_swizzleClassMethod:@selector(sendAsynchronousRequest:queue:completionHandler:) withClassMethod:selector error:error];
}

@end
