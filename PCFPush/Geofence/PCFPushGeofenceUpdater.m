//
// Created by DX173-XL on 2015-04-21.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import "PCFPushGeofenceUpdater.h"
#import "PCFPushGeofenceEngine.h"
#import "PCFPushURLConnection.h"
#import "PCFPushParameters.h"
#import "PCFPushGeofenceResponseData.h"
#import "NSObject+PCFJSONizable.h"
#import "PCFPushPersistentStorage.h"
#import "PCFPushDebug.h"
#import "PCFPushGeofenceStatus.h"
#import "PCFPushGeofenceStatusUtil.h"

static NSString *const GEOFENCE_UPDATE_JSON = @"pivotal.push.geofence_update_json";

static BOOL hasGeofencesInRequest(NSDictionary *userInfo)
{
    return userInfo != nil && userInfo[GEOFENCE_UPDATE_JSON] != nil;
}

@implementation PCFPushGeofenceUpdater

+ (void) startGeofenceUpdate:(PCFPushGeofenceEngine *)engine
                    userInfo:(NSDictionary *)userInfo
                   timestamp:(int64_t)timestamp
                        tags:(NSSet *)subscribedTags
                     success:(void (^)(void))successBlock
                     failure:(void (^)(NSError *error))failureBlock
{
    if (engine == nil) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"engine may not be nil" userInfo:nil];
    }

    PCFPushParameters *parameters = [PCFPushParameters defaultParameters];

    void (^requestSuccessBlock)(NSURLResponse *, NSData *) = ^(NSURLResponse *response, NSData *data) {

        NSError *error;
        PCFPushGeofenceResponseData *responseData = [PCFPushGeofenceResponseData pcfPushFromJSONData:data error:&error];

        if (error) {
            PCFPushCriticalLog(@"Error parsing geofence response data: %@", error);

            PCFPushGeofenceStatus *oldStatus = [PCFPushGeofenceStatusUtil loadGeofenceStatus:[NSFileManager defaultManager]];
            [PCFPushGeofenceStatusUtil updateGeofenceStatusWithError:YES errorReason:error.localizedDescription number:oldStatus.numberOfCurrentlyMonitoredGeofences fileManager:[NSFileManager defaultManager]];

            if (failureBlock) {
                failureBlock(error);
            }
            return;
        }

        [engine processResponseData:responseData withTimestamp:timestamp withTags:subscribedTags];

        [PCFPushPersistentStorage setGeofenceLastModifiedTime:responseData.lastModified];

        if (successBlock) {
            successBlock();
        }
    };

    void (^requestFailureBlock)(NSError *) = ^(NSError *error) {

        PCFPushCriticalLog(@"Fetching geofences request failed: %@", error);

        PCFPushGeofenceStatus *oldStatus = [PCFPushGeofenceStatusUtil loadGeofenceStatus:[NSFileManager defaultManager]];
        [PCFPushGeofenceStatusUtil updateGeofenceStatusWithError:YES errorReason:error.localizedDescription number:oldStatus.numberOfCurrentlyMonitoredGeofences fileManager:[NSFileManager defaultManager]];

        if (failureBlock) {
            failureBlock(error);
        }
    };

    if (hasGeofencesInRequest(userInfo) && pcfPushIsAPNSSandbox()) {
        NSString *geofencesInRequest = userInfo[GEOFENCE_UPDATE_JSON];

        requestSuccessBlock(nil, [geofencesInRequest dataUsingEncoding:NSUTF8StringEncoding]);

    } else {
        PCFPushLog(@"Fetching geofence updates from server with timestamp %lld", timestamp);

        NSString *deviceID = [PCFPushPersistentStorage serverDeviceID];
        [PCFPushURLConnection geofenceRequestWithParameters:parameters timestamp:timestamp deviceUuid:deviceID success:requestSuccessBlock failure:requestFailureBlock];
    }
};

+ (void) clearAllGeofences:(PCFPushGeofenceEngine *)engine
{
    PCFPushLog(@"Clearing all geofences");
    [engine processResponseData:nil withTimestamp:0L withTags:nil];
    [PCFPushPersistentStorage setGeofenceLastModifiedTime:PCF_NEVER_UPDATED_GEOFENCES];
}

@end