//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "PCFPushParameters.h"
#import "PCFPushPersistentStorage.h"
#import "PCFPush.h"
#import "PCFPushClient.h"
#import "PCFPushErrorUtil.h"
#import "PCFPushGeofenceStatusUtil.h"
#import "PCFPushURLConnectionDelegate.h"
#import "PCFTagsHelper.h"
#import "PCFPushDebug.h"
#import "PCFPushServiceInfo.h"
#import "PCFPushSecretUtil.h"

// The current version code is read from "PCFPush.podspec" during a framework build.
// In order to change the project version number, please edit the "PCFPush.podspec" file.
#ifdef _PCF_PUSH_VERSION
#define PCF_PUSH_VERSION @ _PCF_PUSH_VERSION
#else
#define PCF_PUSH_VERSION @ "0.0.0"
#endif

NSString *const PCFPushSDKVersion = PCF_PUSH_VERSION;

// Error domain
NSString *const PCFPushErrorDomain = @"PCFPushErrorDomain";

@implementation PCFPush

+ (void)registerForPCFPushNotificationsWithDeviceToken:(NSData *)deviceToken
                                                  tags:(NSSet<NSString*> *)tags
                                           deviceAlias:(NSString *)deviceAlias
                                   areGeofencesEnabled:(BOOL)areGeofencesEnabled
                                               success:(void (^)(void))successBlock
                                               failure:(void (^)(NSError *))failureBlock
{
    [PCFPush registerForPCFPushNotificationsWithDeviceToken:deviceToken
                                                       tags:tags
                                                deviceAlias:deviceAlias
                                               customUserId:nil
                                        areGeofencesEnabled:areGeofencesEnabled
                                                    success:successBlock
                                                    failure:failureBlock];
}

+ (void)registerForPCFPushNotificationsWithDeviceToken:(NSData *)deviceToken
                                                  tags:(NSSet<NSString*> *)tags
                                           deviceAlias:(NSString *)deviceAlias
                                          customUserId:(NSString *)customUserId
                                   areGeofencesEnabled:(BOOL)areGeofencesEnabled
                                               success:(void (^)(void))successBlock
                                               failure:(void (^)(NSError *))failureBlock
{
    PCFPushClient.shared.registrationParameters = [PCFPushParameters defaultParameters];
    PCFPushClient.shared.registrationParameters.pushDeviceAlias = deviceAlias;
    PCFPushClient.shared.registrationParameters.pushCustomUserId = customUserId;
    PCFPushClient.shared.registrationParameters.pushTags = pcfPushLowercaseTags(tags);
    PCFPushClient.shared.registrationParameters.areGeofencesEnabled = areGeofencesEnabled;
   
    [PCFPushClient.shared registerWithPCFPushWithDeviceToken:deviceToken success:successBlock failure:failureBlock];
}

+ (void) subscribeToTags:(NSSet<NSString*> *)tags success:(void (^)(void))success failure:(void (^)(NSError*))failure
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
    [[PCFPushSecretUtil getStorage] setRequestHeaders:headers];
}

+ (void) setAuthenticationCallback:(PCFPushAuthenticationCallback)authenticationCallback
{
    [PCFPushURLConnectionDelegate setAuthenticationCallback:authenticationCallback];
}

+ (NSString *) sdkVersion
{
    return PCFPushSDKVersion;
}

+ (void) setPushServiceInfo:(PCFPushServiceInfo*)serviceInfo
{
    if (serviceInfo) {
        [PCFPushPersistentStorage setPushApiUrl:serviceInfo.pushApiUrl];
        [PCFPushPersistentStorage setProductionPushPlatformUuid:serviceInfo.productionPushPlatformUuid];
        [PCFPushPersistentStorage setProductionPushPlatformSecret:serviceInfo.productionPushPlatformSecret];
        [PCFPushPersistentStorage setDevelopmentPushPlatformUuid:serviceInfo.developmentPushPlatformUuid];
        [PCFPushPersistentStorage setDevelopmentPushPlatformSecret:serviceInfo.developmentPushPlatformSecret];
    }
}

+ (void) clearPushServiceInfo
{
    [PCFPushPersistentStorage setPushApiUrl:nil];
    [PCFPushPersistentStorage setProductionPushPlatformUuid:nil];
    [PCFPushPersistentStorage setProductionPushPlatformSecret:nil];
    [PCFPushPersistentStorage setDevelopmentPushPlatformUuid:nil];
    [PCFPushPersistentStorage setDevelopmentPushPlatformSecret:nil];
}

+ (void) setPushSecretStorage:(id<PCFPushSecretStorage>)secretStorage
{
    [PCFPushSecretUtil setStorage:secretStorage];
}

@end


