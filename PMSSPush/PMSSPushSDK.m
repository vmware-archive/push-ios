//
//  PMSSPushSDK.m
//  PMSSPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-31.
//  Copyright (c) 2013 Pivotal. All rights reserved.
//

#import "PMSSPushURLConnection.h"
#import "PMSSParameters.h"
#import "PMSSPersistentStorage+Push.h"
#import "PMSSAppDelegateProxy.h"
#import "PMSSPushDebug.h"
#import "PMSSPushSDK.h"
#import "PMSSPushClient.h"
#import "PMSSNotifications.h"

// Error domain
NSString *const PMSSPushErrorDomain = @"PMSSPushErrorDomain";

@implementation PMSSPushSDK

+ (void)load
{
    [[NSNotificationCenter defaultCenter] addObserver:[self class]
                                             selector:@selector(appDidFinishLaunchingNotification:)
                                                 name:UIApplicationDidFinishLaunchingNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:[self class]
                                             selector:@selector(appWillTerminateNotification:)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
}

+ (void)setNotificationTypes:(UIRemoteNotificationType)notificationTypes
{
    [[PMSSPushClient shared] setNotificationTypes:notificationTypes];
}

+ (void)registerForPushNotifications
{
    [[PMSSPushClient shared] registerForRemoteNotifications];
}

+ (void)setRegistrationParameters:(PMSSParameters *)parameters;
{
    if (!parameters) {
        [NSException raise:NSInvalidArgumentException format:@"Parameters may not be nil."];
    }

    PMSSPushClient *pushClient = [PMSSPushClient shared];
    if (pushClient.registrationParameters &&
        [self isRegistered] &&
        pushClient.registrationParameters.pushAutoRegistrationEnabled)
    {
        pushClient.registrationParameters = parameters;
        [pushClient APNSRegistrationSuccess:[PMSSPersistentStorage APNSDeviceToken]];
        
    } else {
        pushClient.registrationParameters = parameters;
    }
}

+ (BOOL)isRegistered
{
    return [PMSSPersistentStorage serverDeviceID] && [PMSSPersistentStorage APNSDeviceToken];
}

+ (void)setRemoteNotificationTypes:(UIRemoteNotificationType)types
{
    [[PMSSPushClient shared] setNotificationTypes:types];
}

+ (void)setCompletionBlockWithSuccess:(void (^)(void))success
                              failure:(void (^)(NSError *error))failure
{
    PMSSPushClient *pushClient = [PMSSPushClient shared];
    pushClient.successBlock = success;
    pushClient.failureBlock = failure;
}

+ (void)unregisterWithPushServerSuccess:(void (^)(void))success
                                failure:(void (^)(NSError *error))failure
{
    [[PMSSPushClient shared] unregisterForRemoteNotificationsWithSuccess:success failure:failure];
}

#pragma mark - Notification Handler Methods

+ (void)appDidFinishLaunchingNotification:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:[self class] name:UIApplicationDidFinishLaunchingNotification object:nil];
    PMSSPushClient *pushClient = [PMSSPushClient shared];
    
    if (pushClient.registrationParameters.pushAutoRegistrationEnabled) {
        [pushClient registerForRemoteNotifications];
    }
}

+ (void)appWillTerminateNotification:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:[self class] name:UIApplicationWillTerminateNotification object:nil];
    UIApplication *application = [UIApplication sharedApplication];
    if ([application.delegate isKindOfClass:[PMSSAppDelegateProxy class]]) {
        @synchronized (application) {
            PMSSAppDelegateProxy *proxyDelegate = application.delegate;
            application.delegate = proxyDelegate.originalAppDelegate;
        }
    }
}

@end
