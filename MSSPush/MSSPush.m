//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "MSSPushURLConnection.h"
#import "MSSParameters.h"
#import "MSSPushPersistentStorage.h"
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
    
    if (![parameters arePushParametersValid]) {
        [NSException raise:NSInvalidArgumentException format:@"Parameters are not valid. See log for more info."];
    }

    MSSPushClient *pushClient = [MSSPushClient shared];
    if (pushClient.registrationParameters &&
        [self isRegistered] &&
        parameters.pushAutoRegistrationEnabled)
    {
        pushClient.registrationParameters = parameters;
        [pushClient APNSRegistrationSuccess:[MSSPushPersistentStorage APNSDeviceToken]];
        
    } else {
        pushClient.registrationParameters = parameters;
    }
}

+ (BOOL)isRegistered
{
    return [MSSPushPersistentStorage serverDeviceID] && [MSSPushPersistentStorage APNSDeviceToken];
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
        MSSPushLog(@"App launch detected. Initiating automatic registration.");
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
