//
// Created by DX173-XL on 15-05-13.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "PCFPushGeofenceUtil.h"
#import "PCFPushGeofenceData.h"
#import "PCFPushGeofenceLocation.h"

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
        case PCFPushTriggerTypeEnterOrExit:
            region.notifyOnEntry = YES;
            region.notifyOnExit = YES;
            break;
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
    return nil;
}

int64_t pcfPushLocationIdForRequestId(NSString *requestId)
{
    NSArray *components = [requestId componentsSeparatedByString:@"_"];
    if (components.count >= 3) {
        return atoll([components[2] cStringUsingEncoding:NSUTF8StringEncoding]);
    }
    return nil;
}

NSString *pcfPushRequestIdWithGeofenceId(int64_t geofenceId, int64_t locationId)
{
    return [NSString stringWithFormat:@"PCF_%lld_%lld", geofenceId, locationId];
}
