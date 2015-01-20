//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "PCFPushParameters.h"
#import "PCFPushPersistentStorage.h"
#import "PCFPush.h"
#import "PCFPushClient.h"

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

+ (void)APNSRegistrationSucceededWithDeviceToken:(NSData *)deviceToken {
    [PCFPushClient.shared APNSRegistrationSuccess:deviceToken];
}

+ (void)APNSRegistrationFailedWithError:(NSError *)error {

    if (PCFPushClient.shared.failureBlock) {
        PCFPushClient.shared.failureBlock(error);
    }
}
@end
