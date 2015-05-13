//
// Created by DX181-XL on 15-04-16.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PCFPushGeofenceDataList;
@class PCFPushGeofenceLocationMap;
@class PCFPushGeofenceLocation;
@class PCFPushGeofenceData;
@class CLLocationManager;
@class CLRegion;

@interface PCFPushGeofenceRegistrar : NSObject

- (instancetype) initWithLocationManager:(CLLocationManager*)locationManager;

- (void) registerGeofences:(PCFPushGeofenceLocationMap *)geofencesToRegister list:(PCFPushGeofenceDataList *)list;
- (void) unregisterGeofences:(PCFPushGeofenceLocationMap *)geofencesToUnregister geofencesToKeep:(PCFPushGeofenceLocationMap *)geofencesToKeep list:(PCFPushGeofenceDataList *)list;
- (void) reset;

@end