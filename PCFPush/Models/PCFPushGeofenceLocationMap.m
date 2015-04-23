//
// Created by DX181-XL on 15-04-17.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import "PCFPushGeofenceLocationMap.h"
#import "PCFPushGeofenceData.h"
#import "PCFPushGeofenceLocation.h"

@interface PCFPushGeofenceLocationMap ()

@property (nonatomic) NSMutableDictionary *dict;

@end

int64_t pcf_geofenceIdForRequestId(NSString *requestId)
{
    NSArray *components = [requestId componentsSeparatedByString:@"_"];
    if (components.count >= 2) {
        return atoll([components[1] cStringUsingEncoding:NSUTF8StringEncoding]);
    }
    return nil;
}

int64_t pcf_locationIdForRequestId(NSString *requestId)
{
    NSArray *components = [requestId componentsSeparatedByString:@"_"];
    if (components.count >= 3) {
        return atoll([components[2] cStringUsingEncoding:NSUTF8StringEncoding]);
    }
    return nil;
}

NSString * pcf_requestIdWithGeofenceId(int64_t geofenceId, int64_t locationId)
{
    return [NSString stringWithFormat:@"PCF_%lld_%lld", geofenceId, locationId];
}

@implementation PCFPushGeofenceLocationMap

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
    NSString *iosRequestId = pcf_requestIdWithGeofenceId(geofence.id, location.id);
    self.dict[iosRequestId] = location;
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