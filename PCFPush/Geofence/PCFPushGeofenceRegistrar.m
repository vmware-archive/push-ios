//
// Created by DX181-XL on 15-04-16.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "PCFPushGeofenceRegistrar.h"
#import "PCFPushGeofenceLocationMap.h"
#import "PCFPushGeofenceLocation.h"
#import "PCFPushDebug.h"
#import "PCFPushParameters.h"
#import "PCFPushGeofenceDataList.h"
#import "PCFPushGeofenceData.h"
#import "PCFPushGeofenceUtil.h"

@interface PCFPushGeofenceRegistrar ()

@property (nonatomic) CLLocationManager *locationManager;

@end

@implementation PCFPushGeofenceRegistrar

- (instancetype) initWithLocationManager:(CLLocationManager*)locationManager
{
    self = [super init];
    if (self) {
        if (!locationManager) {
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"locationManager may not be nil" userInfo:nil];
        }
        self.locationManager = locationManager;
    }
    return self;
}

- (void)registerGeofences:(PCFPushGeofenceLocationMap *)geofencesToRegister list:(PCFPushGeofenceDataList *)list
{
    if (![CLLocationManager isMonitoringAvailableForClass:[CLCircularRegion class]]) {
        PCFPushLog(@"ERROR: isMonitoringAvailableForClass:CLCircularRegion is NOT available. Monitoring of geofences not possible on this device.");
        return;
    }

    [geofencesToRegister enumerateKeysAndObjectsUsingBlock:^(NSString *requestId, PCFPushGeofenceLocation *location, BOOL *stop) {
        int64_t geofenceId = pcfPushGeofenceIdForRequestId(requestId);
        PCFPushGeofenceData *geofence = list[@(geofenceId)];
        CLRegion *region = pcfPushRegionForLocation(requestId, geofence, location);
        [self.locationManager startMonitoringForRegion:region];
        PCFPushLog(@"Now monitoring location '%@'", requestId);
        [self.locationManager requestStateForRegion:region];
    }];

    PCFPushLog(@"Number of monitored geofence locations: %d", geofencesToRegister.count);

    if (pcfPushIsAPNSSandbox()) {
        [self serializeGeofencesForDebug:geofencesToRegister list:list];
    }
}

- (void) unregisterGeofences:(PCFPushGeofenceLocationMap *)geofencesToUnregister geofencesToKeep:(PCFPushGeofenceLocationMap *)geofencesToKeep list:(PCFPushGeofenceDataList *)list
{
    if (![CLLocationManager isMonitoringAvailableForClass:[CLCircularRegion class]]) {
        PCFPushLog(@"ERROR: isMonitoringAvailableForClass:CLCircularRegion is NOT available. Monitoring of geofences not possible on this device.");
        return;
    }

    [geofencesToUnregister enumerateKeysAndObjectsUsingBlock:^(NSString *requestId, PCFPushGeofenceLocation *location, BOOL *stop) {
        int64_t geofenceId = pcfPushGeofenceIdForRequestId(requestId);
        PCFPushGeofenceData *geofence = list[@(geofenceId)];
        CLRegion *region = pcfPushRegionForLocation(requestId, geofence, location);
        [self.locationManager stopMonitoringForRegion:region];
    }];

    PCFPushLog(@"Number of monitored geofence locations: %d", geofencesToKeep.count);

    if (pcfPushIsAPNSSandbox()) {
        [self serializeGeofencesForDebug:geofencesToKeep list:list];
    }
}

- (void)serializeGeofencesForDebug:(PCFPushGeofenceLocationMap *)geofencesToRegister list:(PCFPushGeofenceDataList *)list
{
    NSMutableArray *arr = [NSMutableArray array];

    [geofencesToRegister enumerateKeysAndObjectsUsingBlock:^(NSString *requestId, PCFPushGeofenceLocation *location, BOOL *stop) {
        int64_t geofenceId = pcfPushGeofenceIdForRequestId(requestId);
        PCFPushGeofenceData *data = list[@(geofenceId)];
        NSDictionary *item = @{
                @"lat": [@(location.latitude) stringValue],
                @"long": [@(location.longitude) stringValue],
                @"rad": [@(location.radius) stringValue],
                @"name": location.name,
                @"expiry": [@([data.expiryTime timeIntervalSince1970]) stringValue]
        };
        [arr addObject:item];
    }];

    NSError *error = nil;
    NSData *json = [NSJSONSerialization dataWithJSONObject:arr options:0 error:&error];
    if (!json) {
        PCFPushLog(@"Error serializing monitored geofences to test file for debug: %@", error);
    }

    if (![json writeToFile:self.geofencesFilename options:0 error:&error]) {
        PCFPushLog(@"Error writing monitored geofences to test file for debug: %@", error);
    }

    NSNotification *notification = [NSNotification notificationWithName:@"pivotal.push.geofences.updated" object:nil];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (NSString*) geofencesFilename
{
    NSArray *possibleURLs = [[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask];
    if (!possibleURLs || possibleURLs.count <= 0) {
        PCFPushLog(@"Error getting user library directory.");
        return nil;
    }

    return [((NSURL *) (possibleURLs[0])).path stringByAppendingPathComponent:@"pivotal.push.geofence_status.json"];
}

- (void) reset
{
    for (CLRegion *region in self.locationManager.monitoredRegions) {
        [self.locationManager stopMonitoringForRegion:region];
    }

    PCFPushLog(@"Number of monitored geofence locations: 0");

    if (pcfPushIsAPNSSandbox()) {
        [self clearGeofencesForDebugFile];
    }
}

- (void)clearGeofencesForDebugFile
{
    NSError *error = nil;
    NSString *filename = self.geofencesFilename;
    if ([[NSFileManager defaultManager] fileExistsAtPath:filename]) {
        if (![[NSFileManager defaultManager] removeItemAtPath:filename error:&error]) {
            PCFPushLog(@"Error deleting geofence debug file: %@", error);
        }
    }
}

@end