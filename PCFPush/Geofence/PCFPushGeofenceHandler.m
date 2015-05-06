//
// Created by DX173-XL on 2015-05-04.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "PCFPushGeofenceHandler.h"
#import "PCFPushGeofencePersistentStore.h"
#import "PCFPushGeofenceLocationMap.h"
#import "PCFPushGeofenceData.h"

@interface PCFPushGeofenceHandler()

@property (nonatomic) PCFPushGeofencePersistentStore *store;

@end

static BOOL shouldTriggerNotification(PCFPushGeofenceData *geofence, CLRegionState state) {
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

@implementation PCFPushGeofenceHandler

+ (void)processRegion:(CLRegion *)region store:(PCFPushGeofencePersistentStore *)store state:(CLRegionState)state
{
    if (!store) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"store may not be nil" userInfo:nil];
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
        UILocalNotification *localNotification = [PCFPushGeofenceHandler createNotificationFromGeofence:geofence];
        [UIApplication.sharedApplication presentLocalNotificationNow:localNotification];
    }
}

+ (UILocalNotification *) createNotificationFromGeofence:(PCFPushGeofenceData *)geofence
{
    UILocalNotification *notification = [[UILocalNotification alloc] init];

    // < iOS 8.0
    notification.alertAction = geofence.data[@"ios"][@"alertAction"];
    notification.alertBody = geofence.data[@"ios"][@"alertBody"];
    notification.alertLaunchImage = geofence.data[@"ios"][@"alertLaunchImage"];
    notification.hasAction = [geofence.data[@"ios"][@"hasAction"] boolValue];
    notification.applicationIconBadgeNumber = [geofence.data[@"ios"][@"applicationIconBadgeNumber"] integerValue];
    notification.soundName = geofence.data[@"ios"][@"soundName"];
    notification.userInfo = geofence.data[@"ios"][@"userInfo"];

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

@end