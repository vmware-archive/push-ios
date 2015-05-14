//
// Created by DX173-XL on 15-05-14.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import "PCFPushGeofenceStatusUtil.h"
#import "PCFPushGeofenceStatus.h"
#import "PCFPushDebug.h"
#import "PCFPushGeofenceUtil.h"


@implementation PCFPushGeofenceStatusUtil

+ (PCFPushGeofenceStatus *) loadGeofenceStatus:(NSFileManager *)fileManager
{
    if (!fileManager) {
        return [PCFPushGeofenceStatus emptyStatus];
    }

    NSString *geofencesPath = pcfPushGeofencesPath(fileManager);

    if (!geofencesPath) {
        PCFPushLog(@"Error getting geofences path.");
        return [PCFPushGeofenceStatus emptyStatus];
    }

    NSString *filename = [geofencesPath stringByAppendingPathComponent:@"status.json"];

    BOOL isDirectory = NO;
    BOOL fileExists = [fileManager fileExistsAtPath:filename isDirectory:&isDirectory];
    if (!fileExists || isDirectory) {
        return [PCFPushGeofenceStatus emptyStatus];
    }

    NSError *error;
    NSData *data = [NSData dataWithContentsOfFile:filename options:0 error:&error];

    if (!data) {
        PCFPushLog(@"Error reading contents of geofence status file '%@':", error);
        return [PCFPushGeofenceStatus emptyStatus];
    }

    id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];

    if (!json) {
        PCFPushLog(@"Error deserializing geofence status: %@", error);
        return [PCFPushGeofenceStatus emptyStatus];
    }

    PCFPushGeofenceStatus *status = [PCFPushGeofenceStatus statusWithError:[json[@"isError"] boolValue]
                                                               errorReason:json[@"errorReason"]
                                                                    number:[json[@"numberOfCurrentlyMonitoredGeofences"] unsignedIntegerValue]];
    return status;
}

+ (BOOL) saveGeofenceStatus:(PCFPushGeofenceStatus*)geofenceStatus fileManager:(NSFileManager *)fileManager
{
    if (!geofenceStatus || !fileManager) {
        return NO;
    }

    id dictionary = @{
            @"isError" : @(geofenceStatus.isError),
            @"errorReason" : geofenceStatus.errorReason,
            @"numberOfCurrentlyMonitoredGeofences" : @(geofenceStatus.numberOfCurrentlyMonitoredGeofences) };

    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:&error];

    if (!data) {
        PCFPushLog(@"Error serializing geofence status data: %@", error);
        return NO;
    }

    NSString *geofencesPath = pcfPushGeofencesPath(fileManager);

    if (!geofencesPath) {
        PCFPushLog(@"Error getting geofences path.");
        return NO;
    }

    NSString *filename = [geofencesPath stringByAppendingPathComponent:@"status.json"];

    return [fileManager createFileAtPath:filename contents:data attributes:nil];
}

+ (void) updateGeofenceStatusWithError:(BOOL)isError errorReason:(NSString *)errorReason number:(NSUInteger)numberOfCurrentlyMonitoredGeofences fileManager:(NSFileManager *)fileManager
{
    PCFPushGeofenceStatus *status = [PCFPushGeofenceStatus statusWithError:isError errorReason:errorReason number:numberOfCurrentlyMonitoredGeofences];
    [PCFPushGeofenceStatusUtil saveGeofenceStatus:status fileManager:fileManager];
    [[NSNotificationCenter defaultCenter] postNotificationName:PCF_PUSH_GEOFENCE_STATUS_UPDATE_NOTIFICATION object:nil userInfo:@{@"status":status}];
}

@end