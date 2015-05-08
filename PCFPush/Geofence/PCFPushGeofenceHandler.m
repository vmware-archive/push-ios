//
// Created by DX173-XL on 2015-05-04.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "PCFPushGeofenceHandler.h"
#import "PCFPushGeofencePersistentStore.h"
#import "PCFPushGeofenceLocationMap.h"
#import "PCFPushGeofenceData.h"
#import "PCFPushPersistentStorage.h"
#import "PCFPushGeofenceEngine.h"
#import "PCFPushDebug.h"
#import "PCFPushGeofenceLocation.h"

@interface PCFPushGeofenceHandler()

@property (nonatomic) PCFPushGeofencePersistentStore *store;

@end

static BOOL isUserSubscribedToGeofenceTag(PCFPushGeofenceData *geofence)
{
    if (geofence.tags) {
        NSSet *subscribedTags = [PCFPushPersistentStorage tags];
        BOOL intersects = [subscribedTags intersectsSet:geofence.tags];
        if (!intersects) {
            PCFPushLog(@"Ignoring geofence %lld. Not subscribed to any of its tags.", geofence.id);
        }
        return intersects;
    } else {
        return YES;
    }
}

static BOOL shouldTriggerNotification(PCFPushGeofenceData *geofence, CLRegionState state)
{
    if (state == CLRegionStateUnknown) {
        return NO;
    }

    if (!isUserSubscribedToGeofenceTag(geofence)) {
        return NO;
    }

    switch (geofence.triggerType) {
        case PCFPushTriggerTypeEnterOrExit:
            return YES;
        case PCFPushTriggerTypeEnter:
            return CLRegionStateInside == state;
        case PCFPushTriggerTypeExit:
            return CLRegionStateOutside == state;
        default:
            return NO;
    }
}

static NSDictionary *dictionaryWithTriggerCondition(NSDictionary* dictionary, CLRegionState state)
{
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithDictionary:dictionary];
    switch (state) {
        case CLRegionStateInside:
            result[@"pivotal.push.geofence_trigger_condition"] = @"enter";
            break;
        case CLRegionStateOutside:
            result[@"pivotal.push.geofence_trigger_condition"] = @"exit";
            break;
        default:
            break;
    }
    return result;
}

static UILocalNotification *notificationFromGeofence(PCFPushGeofenceData *geofence, CLRegionState state)
{
    UILocalNotification *notification = [[UILocalNotification alloc] init];

    // < iOS 8.0
    notification.alertAction = geofence.data[@"ios"][@"alertAction"];
    notification.alertBody = geofence.data[@"ios"][@"alertBody"];
    notification.alertLaunchImage = geofence.data[@"ios"][@"alertLaunchImage"];
    notification.hasAction = [geofence.data[@"ios"][@"hasAction"] boolValue];
    notification.applicationIconBadgeNumber = [geofence.data[@"ios"][@"applicationIconBadgeNumber"] integerValue];
    notification.soundName = geofence.data[@"ios"][@"soundName"];
    notification.userInfo = dictionaryWithTriggerCondition(geofence.data[@"ios"][@"userInfo"], state);

    // iOS 8.0+
    if([notification respondsToSelector:@selector(setCategory:)]) {
        notification.category = geofence.data[@"ios"][@"category"];
    }

    // iOS 8.2+
    if([notification respondsToSelector:@selector(setAlertTitle:)]) {
        notification.alertTitle = geofence.data[@"ios"][@"alertTitle"];
    }

    return notification;
}

void clearLocation(NSString *geofenceId, PCFPushGeofenceData *geofence, PCFPushGeofenceEngine *engine)
{
    int64_t locationId = pcf_locationIdForRequestId(geofenceId);
    for (PCFPushGeofenceLocation *location in geofence.locations) {
        if (location.id == locationId) {
            PCFPushGeofenceLocationMap *locationsToClear = [PCFPushGeofenceLocationMap map];
            [locationsToClear put:geofence location:location];
            [engine clearLocations:locationsToClear];
            break;
        }
    }
}

@implementation PCFPushGeofenceHandler

+ (void)processRegion:(CLRegion *)region store:(PCFPushGeofencePersistentStore *)store engine:(PCFPushGeofenceEngine *)engine state:(CLRegionState)state
{
    if (!store) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"store may not be nil" userInfo:nil];
    }

    if (!engine) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"engine may not be nil" userInfo:nil];
    }

    if (!region || !region.identifier || region.identifier.length <= 0) {
        return;
    }
    
    int64_t geofenceId = pcf_geofenceIdForRequestId(region.identifier);
    PCFPushGeofenceData *geofence = store[@(geofenceId)];

    if (!geofence) {
        return;
    }

    if (shouldTriggerNotification(geofence, state)) {
        UILocalNotification *localNotification = notificationFromGeofence(geofence, state);
        [UIApplication.sharedApplication presentLocalNotificationNow:localNotification];

        clearLocation(region.identifier, geofence, engine);
    }
}

@end