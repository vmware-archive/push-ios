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

+ (void)registerForPCFPushNotificationsWithDeviceToken:(NSData *)deviceToken
                                                  tags:(NSSet *)tags
                                           deviceAlias:(NSString *)deviceAlias
                                               success:(void (^)(void))successBlock
                                               failure:(void (^)(NSError *))failureBlock
{
    PCFPushClient.shared.registrationParameters.pushDeviceAlias = deviceAlias;
    PCFPushClient.shared.registrationParameters.pushTags = tags;
    [PCFPushClient.shared registerWithPCFPushWithDeviceToken:deviceToken success:successBlock failure:failureBlock];
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

+ (void)unregisterWithPushServerSuccess:(void (^)(void))success
                                failure:(void (^)(NSError *error))failure
{
    [[PCFPushClient shared] unregisterForRemoteNotificationsWithSuccess:success failure:failure];
}

@end
