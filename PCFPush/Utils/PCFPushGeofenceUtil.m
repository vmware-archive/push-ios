//
// Created by DX173-XL on 15-05-13.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "PCFPushGeofenceUtil.h"
#import "PCFPushGeofenceData.h"
#import "PCFPushGeofenceLocation.h"
#import "PCFPushDebug.h"
#import "PCFPushGeofenceStatus.h"
#import "PCFPushGeofenceStatusUtil.h"

BOOL pcfPushIsItemExpired(PCFPushGeofenceData *geofence)
{
    if (geofence.expiryTime == nil) {
        return YES;
    }

    NSDate *currentDate = [NSDate date];
    NSDate *laterDate = [currentDate laterDate:geofence.expiryTime];
    BOOL isItemExpired = laterDate == currentDate; // If the later date is the current date then the expiry date is in the past and so the item is expired
    return isItemExpired;
}

CLRegion *pcfPushRegionForLocation(NSString *requestId, PCFPushGeofenceData *geofence, PCFPushGeofenceLocation *location)
{
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(location.latitude, location.longitude);
    CLLocationDistance radius = location.radius;
    CLRegion *region = [[CLCircularRegion alloc] initWithCenter:center radius:radius identifier:requestId];

    switch (geofence.triggerType) {
        case PCFPushTriggerTypeEnter:
            region.notifyOnEntry = YES;
            region.notifyOnExit = NO;
            break;
        case PCFPushTriggerTypeExit:
            region.notifyOnEntry = NO;
            region.notifyOnExit = YES;
            break;
        default:
            region.notifyOnEntry = NO;
            region.notifyOnExit = NO;
            break;
    }

    return region;
}

int64_t pcfPushGeofenceIdForRequestId(NSString *requestId)
{
    NSArray *components = [requestId componentsSeparatedByString:@"_"];
    if (components.count >= 2) {
        return atoll([components[1] cStringUsingEncoding:NSUTF8StringEncoding]);
    }
    return PCF_PUSH_NO_GEOFENCE_ID;
}

int64_t pcfPushLocationIdForRequestId(NSString *requestId)
{
    NSArray *components = [requestId componentsSeparatedByString:@"_"];
    if (components.count >= 3) {
        return atoll([components[2] cStringUsingEncoding:NSUTF8StringEncoding]);
    }
    return PCF_PUSH_NO_LOCATION_ID;
}

NSString *pcfPushRequestIdWithGeofenceId(int64_t geofenceId, int64_t locationId)
{
    if (geofenceId >= 0 && locationId >= 0) {
        return [NSString stringWithFormat:@"PCF_%lld_%lld", geofenceId, locationId];
    } else {
        return nil;
    }
}

NSString* pcfPushGeofencesPath(NSFileManager *fileManager)
{
    NSArray *possibleURLs = [fileManager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask];
    if (!possibleURLs || possibleURLs.count <= 0) {
        PCFPushCriticalLog(@"Error getting user library directory.");
        return nil;
    }

    NSURL* url = possibleURLs[0];
    NSString *geofencesPath = [url.path stringByAppendingPathComponent:@"PCF_PUSH_GEOFENCE"];
    return geofencesPath;
}
