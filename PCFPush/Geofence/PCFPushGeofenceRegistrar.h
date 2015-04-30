//
// Created by DX181-XL on 15-04-16.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PCFPushGeofenceDataList;
@class PCFPushGeofenceLocationMap;
@class CLLocationManager;

@interface PCFPushGeofenceRegistrar : NSObject

- (instancetype) initWithLocationManager:(CLLocationManager*)locationManager;

- (void)registerGeofences:(PCFPushGeofenceLocationMap *)geofencesToRegister list:(PCFPushGeofenceDataList *)list;
- (void) reset;

@end