//
//  MSSPush.m
//  MSSPush
//
//  Created by Rob Szumlakowski on 2013-12-31.
//  Copyright (c) 2013 Pivotal. All rights reserved.
//

#import "MSSPushURLConnection.h"
#import "MSSParameters.h"
#import "MSSPersistentStorage+Push.h"
#import "MSSAppDelegateProxy.h"
#import "MSSPushDebug.h"
#import "MSSPush.h"
#import "MSSPushClient.h"
#import "MSSNotifications.h"

// Error domain
NSString *const MSSPushErrorDomain = @"MSSPushErrorDomain";

@implementation MSSPush

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
    [[MSSPushClient shared] setNotificationTypes:notificationTypes];
}

+ (void)registerForPushNotifications
{
    [[MSSPushClient shared] registerForRemoteNotifications];
}

+ (void)setRegistrationParameters:(MSSParameters *)parameters;
{
    if (!parameters) {
        [NSException raise:NSInvalidArgumentException format:@"Parameters may not be nil."];
    }

    MSSPushClient *pushClient = [MSSPushClient shared];
    if (pushClient.registrationParameters &&
        [self isRegistered] &&
        pushClient.registrationParameters.pushAutoRegistrationEnabled)
    {
        pushClient.registrationParameters = parameters;
        [pushClient APNSRegistrationSuccess:[MSSPersistentStorage APNSDeviceToken]];
        
    } else {
        pushClient.registrationParameters = parameters;
    }
}

+ (BOOL)isRegistered
{
    return [MSSPersistentStorage serverDeviceID] && [MSSPersistentStorage APNSDeviceToken];
}

+ (void)setRemoteNotificationTypes:(UIRemoteNotificationType)types
{
    [[MSSPushClient shared] setNotificationTypes:types];
}

+ (void)setCompletionBlockWithSuccess:(void (^)(void))success
                              failure:(void (^)(NSError *error))failure
{
    MSSPushClient *pushClient = [MSSPushClient shared];
    pushClient.successBlock = success;
    pushClient.failureBlock = failure;
}

+ (void)unregisterWithPushServerSuccess:(void (^)(void))success
                                failure:(void (^)(NSError *error))failure
{
    [[MSSPushClient shared] unregisterForRemoteNotificationsWithSuccess:success failure:failure];
}

#pragma mark - Notification Handler Methods

+ (void)appDidFinishLaunchingNotification:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:[self class] name:UIApplicationDidFinishLaunchingNotification object:nil];
    MSSPushClient *pushClient = [MSSPushClient shared];
    
    if (pushClient.registrationParameters.pushAutoRegistrationEnabled) {
        [pushClient registerForRemoteNotifications];
    }
}

+ (void)appWillTerminateNotification:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:[self class] name:UIApplicationWillTerminateNotification object:nil];
    UIApplication *application = [UIApplication sharedApplication];
    if ([application.delegate isKindOfClass:[MSSAppDelegateProxy class]]) {
        @synchronized (application) {
            MSSAppDelegateProxy *proxyDelegate = application.delegate;
            application.delegate = proxyDelegate.originalAppDelegate;
        }
    }
}

@end
