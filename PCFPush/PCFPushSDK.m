//
//  PCFPushSDK.m
//  PCFPushSDK
//
//  Created by Rob Szumlakowski on 2013-12-31.
//  Copyright (c) 2013 Pivotal. All rights reserved.
//

#import "PCFPushURLConnection.h"
#import "PCFPushParameters.h"
#import "PCFPushPersistentStorage.h"
#import "PCFPushAppDelegateProxy.h"
#import "PCFPushDebug.h"
#import "PCFPushSDK.h"
#import "PCFPushClient.h"

NSString *const PCFPushErrorDomain = @"PCFPushErrorDomain";

@implementation PCFPushSDK

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
    [[PCFPushClient shared] setNotificationTypes:notificationTypes];
}

+ (void)setRegistrationParameters:(PCFPushParameters *)parameters;
{
    if (!parameters) {
        [NSException raise:NSInvalidArgumentException format:@"Parameters may not be nil."];
    }

    PCFPushClient *pushClient = [PCFPushClient shared];
    if (pushClient.registrationParameters && [self isRegistered]) {
        pushClient.registrationParameters = parameters;
        [pushClient APNSRegistrationSuccess:[PCFPushPersistentStorage APNSDeviceToken]];
        
    } else {
        pushClient.registrationParameters = parameters;
    }
}

+ (BOOL)isRegistered
{
    return [PCFPushPersistentStorage pushServerDeviceID] && [PCFPushPersistentStorage APNSDeviceToken];
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
    [PCFPushURLConnection unregisterDeviceID:[PCFPushPersistentStorage pushServerDeviceID]
                                     success:^(NSURLResponse *response, NSData *data) {
                                         [PCFPushPersistentStorage reset];
                                         
                                         if (success) {
                                             success();
                                         }
                                     }
                                     failure:failure];
}

#pragma mark - Notification Handler Methods

+ (void)appDidFinishLaunchingNotification:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:[self class] name:UIApplicationDidFinishLaunchingNotification object:nil];
    PCFPushClient *pushClient = [PCFPushClient shared];
    
    if (![pushClient registrationParameters]) {
        PCFPushParameters *params = [PCFPushParameters defaultParameters];
        
        if (!params) {
            PCFPushLog(@"PCFPush registration parameters not set in application:didFinishLaunchingWithOptions:");
            return;
        }
        [pushClient setRegistrationParameters:params];
    }
    
    if (pushClient.registrationParameters.autoRegistrationEnabled) {
        [pushClient registerForRemoteNotifications];
    }
}

+ (void)appWillTerminateNotification:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:[self class] name:UIApplicationWillTerminateNotification object:nil];
    
    UIApplication *application = [UIApplication sharedApplication];
    if ([application.delegate isKindOfClass:[PCFPushAppDelegateProxy class]]) {
        @synchronized (application) {
            PCFPushAppDelegateProxy *proxyDelegate = application.delegate;
            application.delegate = proxyDelegate.originalAppDelegate;
        }
    }
    
    [PCFPushClient resetSharedPushClient];
}

#warning - TODO: Extract into Analytics library

+ (BOOL)analyticsEnabled
{
    return [PCFPushPersistentStorage analyticsEnabled];
}

+ (void)setAnalyticsEnabled:(BOOL)enabled
{
    [PCFPushPersistentStorage setAnalyticsEnabled:enabled];
}

@end
