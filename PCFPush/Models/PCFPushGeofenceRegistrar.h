//
// Created by DX181-XL on 15-04-16.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PCFPushGeofenceDataList;
@class PCFPushGeofenceLocationMap;

@interface PCFPushGeofenceRegistrar : NSObject

- (void) registerGeofences:(PCFPushGeofenceLocationMap*)geofencesToRegister geofenceDataList:(PCFPushGeofenceDataList*)geofenceDataList;
- (void) reset;

@end