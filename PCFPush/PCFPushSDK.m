//
//  PCFPushSDK.m
//  PCFPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-31.
//  Copyright (c) 2013 Pivotal. All rights reserved.
//

#import "PCFPushURLConnection.h"
#import "PCFParameters.h"
#import "PCFPersistentStorage+Push.h"
#import "PCFAppDelegateProxy.h"
#import "PCFPushDebug.h"
#import "PCFPushSDK.h"
#import "PCFPushClient.h"

NSString *const PCFPushErrorDomain = @"PCFPushErrorDomain";

@implementation PCFPushSDK

+ (void)setNotificationTypes:(UIRemoteNotificationType)notificationTypes
{
    [[PCFPushClient shared] setNotificationTypes:notificationTypes];
}

+ (void)setRegistrationParameters:(PCFParameters *)parameters;
{
    if (!parameters) {
        [NSException raise:NSInvalidArgumentException format:@"Parameters may not be nil."];
    }

    PCFPushClient *pushClient = [PCFPushClient shared];
    if (pushClient.registrationParameters && [self isRegistered]) {
        pushClient.registrationParameters = parameters;
        [pushClient APNSRegistrationSuccess:[PCFPersistentStorage APNSDeviceToken]];
        
    } else {
        pushClient.registrationParameters = parameters;
    }
}

+ (BOOL)isRegistered
{
    return [PCFPersistentStorage serverDeviceID] && [PCFPersistentStorage APNSDeviceToken];
}

+ (void)setRemoteNotificationTypes:(UIRemoteNotificationType)types
{
    [[PCFPushClient shared] setNotificationTypes:types];
}

+ (void)setCompletionBlockWithSuccess:(void (^)(void))success
                              failure:(void (^)(NSError *error))failure
{
    PCFPushClient *pushClient = [PCFPushClient shared];
    pushClient.successBlock = success;
    pushClient.failureBlock = failure;
}

+ (void)unregisterWithPushServerSuccess:(void (^)(void))success
                                failure:(void (^)(NSError *error))failure
{
    [PCFPushURLConnection unregisterDeviceID:[PCFPersistentStorage serverDeviceID]
                                     success:^(NSURLResponse *response, NSData *data) {
                                         [PCFPersistentStorage resetPushPersistedValues];
                                         
                                         if (success) {
                                             success();
                                         }
                                     }
                                     failure:failure];
}

#pragma mark - Notification Handler Methods

+ (void)appDidFinishLaunchingNotification:(NSNotification *)notification
{
    [super appDidFinishLaunchingNotification:notification];
    
    PCFPushClient *pushClient = [PCFPushClient shared];
    
    if (pushClient.registrationParameters.autoRegistrationEnabled) {
        [pushClient registerForRemoteNotifications];
    }
}

+ (void)appWillTerminateNotification:(NSNotification *)notification
{
    [super appWillTerminateNotification:notification];
    
    UIApplication *application = [UIApplication sharedApplication];
    if ([application.delegate isKindOfClass:[PCFAppDelegateProxy class]]) {
        @synchronized (application) {
            PCFAppDelegateProxy *proxyDelegate = application.delegate;
            application.delegate = proxyDelegate.originalAppDelegate;
        }
    }
}

@end
