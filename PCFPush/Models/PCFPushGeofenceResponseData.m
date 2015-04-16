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
    if ([propertyName isEqualToString:@"lastModified"]) {
        if ([value isKindOfClass:[NSNumber class]]) {
            NSTimeInterval secondsSince1970 = [value longLongValue] / 1000.0;
            self.lastModified = [NSDate dateWithTimeIntervalSince1970:secondsSince1970];
        }
        return YES;

    } else if ([propertyName isEqualToString:@"geofences"]) {
        if ([value isKindOfClass:[NSArray class]]) {
            NSArray *geofences = (NSArray *) value;
            if (geofences.count > 0) {
                NSMutableArray *arr = [NSMutableArray array];
                for (id geofence in geofences) {
                    PCFPushGeofenceData *l = [PCFPushGeofenceData pcf_fromDictionary:geofence];
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
    if ([propertyName isEqualToString:@"lastModified"]) {
        if ([value isKindOfClass:[NSDate class]]) {
            NSNumber *d = @((int64_t) ([self.lastModified timeIntervalSince1970] * 1000.0));
            destination[@"last_modified"] = d;
        }
        return YES;

    } else if ([propertyName isEqualToString:@"geofences"]) {

        if ([value isKindOfClass:[NSArray class]]) {
            NSArray *geofences = (NSArray*)value;
            if (geofences.count > 0) {
                NSMutableArray *arr = [NSMutableArray array];
                for (PCFPushGeofenceData *geofence in geofences) {
                    id g = [geofence pcf_toFoundationType];
                    [arr addObject:g];
                }
                destination[@"geofences"] = arr;
            }
        }
        return YES;
    }

    return NO;
}

@end