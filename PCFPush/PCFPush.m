//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "PCFPushURLConnection.h"
#import "PCFPushParameters.h"
#import "PCFPushPersistentStorage.h"
#import "PCFAppDelegateProxy.h"
#import "PCFPushDebug.h"
#import "PCFPush.h"
#import "PCFPushClient.h"
#import "PCFNotifications.h"

// Error domain
NSString *const PCFPushErrorDomain = @"PCFPushErrorDomain";

@implementation PCFPush

+ (void)load
{
    [[NSNotificationCenter defaultCenter] addObserver:[self class]
                                             selector:@selector(appWillTerminateNotification:)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
}

+ (void)setNotificationTypes:(UIRemoteNotificationType)notificationTypes
{
    [[PCFPushClient shared] setNotificationTypes:notificationTypes];
}

+ (void)registerForPushNotifications
{
    [[PCFPushClient shared] registerForRemoteNotifications];
}

+ (void) setDeviceAlias:(NSString *)deviceAlias {
    PCFPushClient.shared.registrationParameters.pushDeviceAlias = deviceAlias;
}

+ (void) setTags:(NSSet *)tags {
    PCFPushClient.shared.registrationParameters.pushTags = tags;
}

+ (BOOL)isRegistered
{
    return [PCFPushPersistentStorage serverDeviceID] && [PCFPushPersistentStorage APNSDeviceToken];
}

// TODO - make sure that this method is covered by tests
+ (void)setRemoteNotificationTypes:(UIRemoteNotificationType)types
{
    PCFPushClient.shared.notificationTypes = types;
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
    [[PCFPushClient shared] unregisterForRemoteNotificationsWithSuccess:success failure:failure];
}

#pragma mark - Notification Handler Methods

+ (void)appWillTerminateNotification:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:[self class] name:UIApplicationWillTerminateNotification object:nil];
    UIApplication *application = [UIApplication sharedApplication];
    if ([application.delegate isKindOfClass:[PCFAppDelegateProxy class]]) {
        @synchronized (application) {
            PCFAppDelegateProxy *proxyDelegate = application.delegate;
            application.delegate = proxyDelegate.originalAppDelegate;
        }
    }
}

@end
