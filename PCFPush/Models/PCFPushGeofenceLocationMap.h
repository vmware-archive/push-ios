//
// Created by DX181-XL on 15-04-17.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PCFPushGeofenceData;
@class PCFPushGeofenceLocation;

@interface PCFPushGeofenceLocationMap : NSObject

- (NSUInteger) count;

+ (NSString *)iosRequestIdWithGeofenceId:(int64_t)geofenceId locationId:(int64_t)locationId;

- (id)objectForKeyedSubscript:(id <NSCopying>)key;
- (void)setObject:(id)obj forKeyedSubscript:(id <NSCopying>)key;
- (void) put:(PCFPushGeofenceData*)geofence location:(PCFPushGeofenceLocation*)location;
- (void) put:(PCFPushGeofenceData*)geofence locationIndex:(NSUInteger)locationIndex;
- (BOOL)isEqual:(id)anObject;

@end