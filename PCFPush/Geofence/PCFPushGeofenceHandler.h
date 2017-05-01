//
// Created by DX173-XL on 2015-05-04.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@class PCFPushGeofencePersistentStore;
@class PCFPushGeofenceEngine;
@class PCFPushGeofenceData;

@interface PCFPushGeofenceHandler : NSObject

+ (BOOL) localNotificationRespondsToSetCategory:(UILocalNotification*)notification;
+ (BOOL) localNotificationRespondsToSetAlertTitle:(UILocalNotification*)notification;

+ (void)processRegion:(CLRegion *)region
                store:(PCFPushGeofencePersistentStore *)store
               engine:(PCFPushGeofenceEngine *)engine
                state:(CLRegionState)state
           parameters:(PCFPushParameters *)parameters;

+ (void) reregisterGeofencesWithEngine:(PCFPushGeofenceEngine *)engine subscribedTags:(NSSet<NSString*> *)subscribedTags;

@end
