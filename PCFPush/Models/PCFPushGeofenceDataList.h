//
// Created by DX181-XL on 15-04-16.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PCFPushGeofenceData;

@interface PCFPushGeofenceDataList : NSObject

- (void)addEntriesFromDictionary:(NSDictionary *)dict;
- (id)objectForKeyedSubscript:(id <NSCopying>)key;
- (void)setObject:(id)obj forKeyedSubscript:(id <NSCopying>)key;
- (void)enumerateKeysAndObjectsUsingBlock:(void (^)(int64_t id, PCFPushGeofenceData *geofence, BOOL *stop))block;
- (NSUInteger) count;
- (BOOL)isEqual:(id)anObject;

@end