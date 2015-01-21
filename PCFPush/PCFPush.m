//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "PCFPushParameters.h"
#import "PCFPushPersistentStorage.h"
#import "PCFPush.h"
#import "PCFPushClient.h"
#import "PCFPushErrors.h"
#import "PCFPushErrorUtil.h"

// Error domain
NSString *const PCFPushErrorDomain = @"PCFPushErrorDomain";

@implementation PCFPush

+ (void)setNotificationTypes:(UIRemoteNotificationType)notificationTypes
{
    [[PCFPushClient shared] setNotificationTypes:notificationTypes];
}

+ (void)registerForPushNotifications
{
    [[PCFPushClient shared] registerForRemoteNotifications];
}

+ (void) registerForPushNotificationsWithTags:(NSSet *)tags
{
    PCFPushClient.shared.registrationParameters.pushTags = tags;
    [[PCFPushClient shared] registerForRemoteNotifications];
}

+ (void) registerForPushNotificationsWithDeviceAlias:(NSString *)deviceAlias
{
    PCFPushClient.shared.registrationParameters.pushDeviceAlias = deviceAlias;
    [[PCFPushClient shared] registerForRemoteNotifications];
}

+ (void) registerForPushNotificationsWithDeviceAlias:(NSString *)deviceAlias tags:(NSSet *)tags
{
    PCFPushClient.shared.registrationParameters.pushDeviceAlias = deviceAlias;
    PCFPushClient.shared.registrationParameters.pushTags = tags;
    [[PCFPushClient shared] registerForRemoteNotifications];
}

+ (void) subscribeToTags:(NSSet *)tags success:(void (^)(void))success failure:(void (^)(NSError*))failure
{
    NSData *deviceToken = [PCFPushPersistentStorage APNSDeviceToken];
    NSString *deviceUuid = [PCFPushPersistentStorage serverDeviceID];

    if (!deviceToken || !deviceUuid) {
        if (failure) {
            NSError *error = [PCFPushErrorUtil errorWithCode:PCFPushNotRegistered localizedDescription:@"Your device must be registered before you can attempt to subscribe to tags"];
            failure(error);
        }
        return;
    }

    [PCFPushClient.shared subscribeToTags:tags deviceToken:deviceToken deviceUuid:deviceUuid success:success failure:failure];
}

// TODO - make sure that this method is covered by tests
// TODO - this method does not need to exist
+ (void)setRemoteNotificationTypes:(UIRemoteNotificationType)types
{
    PCFPushClient.shared.notificationTypes = types;
}

// TODO - this method does not need to exist
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

// TODO - this method should accept success and failure blocks
+ (void)APNSRegistrationSucceededWithDeviceToken:(NSData *)deviceToken {
    [PCFPushClient.shared APNSRegistrationSuccess:deviceToken];
}

// TODO - this method does not need to exist
+ (void)APNSRegistrationFailedWithError:(NSError *)error {

    if (PCFPushClient.shared.failureBlock) {
        PCFPushClient.shared.failureBlock(error);
    }
}
@end
