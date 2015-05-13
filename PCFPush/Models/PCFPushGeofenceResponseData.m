//
// Created by DX181-XL on 15-04-15.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import "PCFPushGeofenceResponseData.h"
#import "PCFPushGeofenceData.h"
#import "NSObject+PCFJSONizable.h"

@implementation PCFPushGeofenceResponseData

+ (NSDictionary *)localToRemoteMapping
{
    static NSDictionary *localToRemoteMapping;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        localToRemoteMapping = @{
                PCF_STR_PROP(number) : @"num",
                PCF_STR_PROP(lastModified) : @"last_modified",
                PCF_STR_PROP(geofences) : @"geofences",
                PCF_STR_PROP(deletedGeofenceIds) : @"deleted_geofence_ids"
        };
    });
    return localToRemoteMapping;
}

- (BOOL)handleDeserializingProperty:(NSString *)propertyName value:(id)value
{
    if ([propertyName isEqualToString:@"geofences"]) {
        if ([value isKindOfClass:[NSArray class]]) {
            NSArray *geofences = (NSArray *) value;
            if (geofences.count > 0) {
                NSMutableArray *arr = [NSMutableArray array];
                for (id geofence in geofences) {
                    PCFPushGeofenceData *l = [PCFPushGeofenceData pcfPushFromDictionary:geofence];
                    [arr addObject:l];
                }
                self.geofences = arr;
            }
        }
        return YES;
    }

    return NO;
}

- (BOOL)handleSerializingProperty:(NSString *)propertyName value:(id)value destination:(NSMutableDictionary *)destination
{
    if ([propertyName isEqualToString:@"geofences"]) {

        if ([value isKindOfClass:[NSArray class]]) {
            NSArray *geofences = (NSArray*)value;
            if (geofences.count > 0) {
                NSMutableArray *arr = [NSMutableArray array];
                for (PCFPushGeofenceData *geofence in geofences) {
                    id g = [geofence pcfPushToFoundationType];
                    [arr addObject:g];
                }
                destination[@"geofences"] = arr;
            }
        }
        return YES;
    }

    return NO;
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![[other class] isEqual:[self class]])
        return NO;

    return [self isEqualToData:other];
}

- (BOOL)isEqualToData:(PCFPushGeofenceResponseData *)data {
    if (self == data)
        return YES;
    if (data == nil)
        return NO;
    if (self.number != data.number)
        return NO;
    if (self.lastModified != data.lastModified)
        return NO;
    if (self.geofences != data.geofences && ![self.geofences isEqualToArray:data.geofences])
        return NO;
    if (self.deletedGeofenceIds != data.deletedGeofenceIds && ![self.deletedGeofenceIds isEqualToArray:data.deletedGeofenceIds])
        return NO;
    return YES;
}

- (NSUInteger)hash {
    NSUInteger hash = (NSUInteger) self.number;
    hash = hash * 31u + (NSUInteger) self.lastModified;
    hash = hash * 31u + [self.geofences hash];
    hash = hash * 31u + [self.deletedGeofenceIds hash];
    return hash;
}

@end