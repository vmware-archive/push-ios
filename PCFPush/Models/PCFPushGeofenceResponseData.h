//
// Created by DX181-XL on 15-04-15.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PCFMapping.h"

@interface PCFPushGeofenceResponseData : NSObject<PCFMapping>

@property int64_t number;
@property int64_t lastModified;
@property NSArray *geofences;
@property NSArray *deletedGeofenceIds;

- (BOOL)isEqual:(id)other;

- (BOOL)isEqualToData:(PCFPushGeofenceResponseData *)data;

- (NSUInteger)hash;

@end