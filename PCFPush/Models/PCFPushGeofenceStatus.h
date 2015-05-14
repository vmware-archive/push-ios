//
// Created by DX173-XL on 15-05-14.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* PCF_PUSH_GEOFENCE_STATUS_UPDATE_NOTIFICATION;

@interface PCFPushGeofenceStatus : NSObject

@property (readonly) BOOL isError;
@property (readonly) NSString *errorReason;
@property (readonly) NSUInteger numberOfCurrentlyMonitoredGeofences;

+ (instancetype) statusWithError:(BOOL)isError errorReason:(NSString*)errorReason number:(NSUInteger)numberOfCurrentlyMonitoringGeofences;
+ (instancetype) emptyStatus;

- (BOOL)isEqual:(id)other;

- (BOOL)isEqualToStatus:(PCFPushGeofenceStatus *)status;

- (NSUInteger)hash;

@end