//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "PCFPushParameters.h"
#import "PCFPushPersistentStorage.h"
#import "PCFPush.h"
#import "PCFPushClient.h"
#import "PCFPushErrorUtil.h"
#import "PCFPushGeofenceStatusUtil.h"
#import "PCFTagsHelper.h"

// Error domain
NSString *const PCFPushErrorDomain = @"PCFPushErrorDomain";

@implementation PCFPush

+ (void)registerForPCFPushNotificationsWithDeviceToken:(NSData *)deviceToken
                                                  tags:(NSSet *)tags
                                           deviceAlias:(NSString *)deviceAlias
                                   areGeofencesEnabled:(BOOL)areGeofencesEnabled
                                               success:(void (^)(void))successBlock
                                               failure:(void (^)(NSError *))failureBlock
{
    PCFPushClient.shared.registrationParameters.pushDeviceAlias = deviceAlias;
    PCFPushClient.shared.registrationParameters.pushTags = pcfPushLowercaseTags(tags);
    PCFPushClient.shared.registrationParameters.areGeofencesEnabled = areGeofencesEnabled;
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

    [PCFPushClient.shared subscribeToTags:pcfPushLowercaseTags(tags) deviceToken:deviceToken deviceUuid:deviceUuid success:success failure:failure];
}

+ (void)unregisterFromPCFPushNotificationsWithSuccess:(void (^)(void))success
                                              failure:(void (^)(NSError *))failure
{
    [PCFPushClient.shared unregisterForRemoteNotificationsWithSuccess:success failure:failure];
}

+ (void)didReceiveRemoteNotification:(NSDictionary*)userInfo
                   completionHandler:(void (^)(BOOL wasIgnored, UIBackgroundFetchResult fetchResult, NSError *error))handler
{
    [PCFPushClient.shared didReceiveRemoteNotification:userInfo completionHandler:handler];
}

+ (void)setAreGeofencesEnabled:(BOOL)areGeofencesEnabled success:(void (^)(void))success failure:(void (^)(NSError*))failure
{
    NSData *deviceToken = [PCFPushPersistentStorage APNSDeviceToken];
    if (!deviceToken) {
        if (failure) {
            NSError *error = [PCFPushErrorUtil errorWithCode:PCFPushNotRegistered localizedDescription:@"Your device must be registered before you can attempt to toggle geofences"];
            failure(error);
        }
        return;
    }

    PCFPushClient.shared.registrationParameters.areGeofencesEnabled = areGeofencesEnabled;

    [PCFPushClient.shared registerWithPCFPushWithDeviceToken:deviceToken success:success failure:failure];
}

+ (PCFPushGeofenceStatus*) geofenceStatus
{
    return [PCFPushGeofenceStatusUtil loadGeofenceStatus:[NSFileManager defaultManager]];
}

+ (NSString*)deviceUuid
{
    return [PCFPushPersistentStorage serverDeviceID];
}

+ (void) setRequestHeaders:(NSDictionary*)headers
{
    [PCFPushPersistentStorage setRequestHeaders:headers];
}

@end
