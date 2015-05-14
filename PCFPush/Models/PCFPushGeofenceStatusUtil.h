//
// Created by DX173-XL on 15-05-14.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PCFPushGeofenceStatus;

@interface PCFPushGeofenceStatusUtil : NSObject

+ (PCFPushGeofenceStatus *) loadGeofenceStatus:(NSFileManager *)fileManager;

+ (BOOL) saveGeofenceStatus:(PCFPushGeofenceStatus*)geofenceStatus fileManager:(NSFileManager *)fileManager;

+ (void) updateGeofenceStatusWithError:(BOOL)isError errorReason:(NSString *)errorReason number:(NSUInteger)numberOfCurrentlyMonitoredGeofences fileManager:(NSFileManager *)fileManager;

@end