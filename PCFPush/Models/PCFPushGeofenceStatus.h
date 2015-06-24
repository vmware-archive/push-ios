//
// Created by DX173-XL on 15-05-14.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* PCF_PUSH_GEOFENCE_STATUS_UPDATE_NOTIFICATION;

@interface PCFPushGeofenceStatus : NSObject

/**
 * This field will be set if some kind of error happens while PCF Push tries
 * to update or monitor geofences.
 */
@property (readonly) BOOL isError;

/**
 * The error reason (if there is one).
 */
@property (readonly) NSString *errorReason;

/**
 * The number of geofences currently being monitored.
 */
@property (readonly) NSUInteger numberOfCurrentlyMonitoredGeofences;

+ (instancetype) statusWithError:(BOOL)isError errorReason:(NSString*)errorReason number:(NSUInteger)numberOfCurrentlyMonitoringGeofences;
+ (instancetype) emptyStatus;

- (BOOL)isEqual:(id)other;

- (BOOL)isEqualToStatus:(PCFPushGeofenceStatus *)status;

- (NSUInteger)hash;

@end