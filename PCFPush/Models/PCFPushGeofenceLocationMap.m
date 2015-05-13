//
// Created by DX181-XL on 15-04-17.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import "PCFPushGeofenceLocationMap.h"
#import "PCFPushGeofenceData.h"
#import "PCFPushGeofenceLocation.h"
#import "PCFPushGeofenceDataList.h"
#import "PCFPushGeofenceUtil.h"

@interface PCFPushGeofenceLocationMap ()

@property (nonatomic) NSMutableDictionary *dict;

@end

@implementation PCFPushGeofenceLocationMap

+ (instancetype) map
{
    return [[PCFPushGeofenceLocationMap alloc] init];
}

+ (instancetype) mapWithGeofencesInList:(PCFPushGeofenceDataList *)list
{
    PCFPushGeofenceLocationMap *map = [[PCFPushGeofenceLocationMap alloc] init];
    [list enumerateKeysAndObjectsUsingBlock:^(int64_t id, PCFPushGeofenceData *geofence, BOOL *stop) {
        for (PCFPushGeofenceLocation *location in geofence.locations) {
            if (geofence.id >= 0 && location.id >= 0) {
                [map put:geofence location:location];
            }
        }
    }];
    return map;
}

- (instancetype) init
{
    self = [super init];
    if (self) {
        self.dict = [NSMutableDictionary dictionary];
    }
    return self;
}

- (BOOL)isEqual:(id)o
{
    if (![o isKindOfClass:[PCFPushGeofenceLocationMap class]]) {
        return NO;
    }
    PCFPushGeofenceLocationMap *other = (PCFPushGeofenceLocationMap *)o;
    return [other.dict isEqual:self.dict];
}

- (NSUInteger) count
{
    return self.dict.count;
}

- (void) put:(PCFPushGeofenceData*)geofence locationIndex:(NSUInteger)locationIndex
{
    PCFPushGeofenceLocation *location = geofence.locations[locationIndex];
    [self put:geofence location:location];
}

- (void) put:(PCFPushGeofenceData*)geofence location:(PCFPushGeofenceLocation*)location
{
    NSString *iosRequestId = pcfPushRequestIdWithGeofenceId(geofence.id, location.id);
    if (iosRequestId) {
        self.dict[iosRequestId] = location;
    }
}

- (id)objectForKeyedSubscript:(id <NSCopying>)key
{
    return self.dict[key];
}

- (void)setObject:(id)obj forKeyedSubscript:(id <NSCopying>)key
{
    self.dict[key] = obj;
}

- (void)enumerateKeysAndObjectsUsingBlock:(void (^)(NSString *requestId, PCFPushGeofenceLocation *location, BOOL *stop))block
{
    [self.dict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        block(key, obj, stop);
    }];
}

@end