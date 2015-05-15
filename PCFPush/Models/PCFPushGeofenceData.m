//
//  PCFPushGeofenceData.m
//  PCFPush
//
//  Created by DX181-XL on 2015-04-14.
//  Copyright (c) 2015 Pivotal. All rights reserved.
//

#import "PCFPushGeofenceData.h"
#import "PCFPushGeofenceLocation.h"
#import "NSObject+PCFJSONizable.h"

@implementation PCFPushGeofenceData

+ (NSDictionary *)localToRemoteMapping
{
    static NSDictionary *localToRemoteMapping;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        localToRemoteMapping = @{
                                 PCF_STR_PROP(id) : @"id",
                                 PCF_STR_PROP(data) : @"data",
                                 PCF_STR_PROP(triggerType) : @"trigger_type",
                                 PCF_STR_PROP(expiryTime) : @"expiry_time",
                                 PCF_STR_PROP(locations) : @"locations",
                                 PCF_STR_PROP(tags) : @"tags"
                                 };
    });
    return localToRemoteMapping;
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![[other class] isEqual:[self class]])
        return NO;

    return [self isEqualToData:other];
}

- (BOOL)isEqualToData:(PCFPushGeofenceData *)data {
    if (self == data)
        return YES;
    if (data == nil)
        return NO;
    if (self.id != data.id)
        return NO;
    if (self.expiryTime != data.expiryTime && ![self.expiryTime isEqualToDate:data.expiryTime])
        return NO;
    if (self.locations != data.locations && ![self.locations isEqualToArray:data.locations])
        return NO;
    if (self.data != data.data && ![self.data isEqualToDictionary:data.data])
        return NO;
    if (self.tags != data.tags && ![self.tags isEqualToSet:data.tags])
        return NO;
    if (self.triggerType != data.triggerType)
        return NO;
    return YES;
}

- (NSUInteger)hash {
    NSUInteger hash = (NSUInteger) self.id;
    hash = hash * 31u + [self.expiryTime hash];
    hash = hash * 31u + [self.locations hash];
    hash = hash * 31u + [self.data hash];
    hash = hash * 31u + [self.tags hash];
    hash = hash * 31u + (NSUInteger) self.triggerType;
    return hash;
}

- (instancetype)newCopyWithoutLocations
{
    PCFPushGeofenceData *newCopy = [[PCFPushGeofenceData alloc] init];
    newCopy.id = self.id;
    newCopy.data = self.data;
    newCopy.triggerType = self.triggerType;
    newCopy.expiryTime = self.expiryTime;
    newCopy.tags = self.tags;
    return newCopy;
}

- (BOOL)handleDeserializingProperty:(NSString *)propertyName value:(id)value
{
    if ([propertyName isEqualToString:@"expiryTime"]) {
        if ([value isKindOfClass:[NSNumber class]]) {
            NSTimeInterval secondsSince1970 = [value longLongValue] / 1000.0;
            self.expiryTime = [NSDate dateWithTimeIntervalSince1970:secondsSince1970];
        }
        return YES;
        
    } else if ([propertyName isEqualToString:@"triggerType"]) {
        if ([value isKindOfClass:[NSString class]]) {
            if ([value isEqualToString:@"enter"]) {
                self.triggerType = PCFPushTriggerTypeEnter;
            } else if ([value isEqualToString:@"exit"]) {
                self.triggerType = PCFPushTriggerTypeExit;
            }
        }
        return YES;

    } else if ([propertyName isEqualToString:@"locations"]) {
        if ([value isKindOfClass:[NSArray class]]) {
            NSArray *locations = (NSArray *) value;
            if (locations.count > 0) {
                NSMutableArray *arr = [NSMutableArray array];
                for (id location in locations) {
                    PCFPushGeofenceLocation *l = [PCFPushGeofenceLocation pcfPushFromDictionary:location];
                    [arr addObject:l];
                }
                self.locations = arr;
            }
        }
        return YES;

    } else if ([propertyName isEqualToString:@"tags"]) {
        if ([value isKindOfClass:[NSArray class]]) {
            NSArray *tags = (NSArray *) value;
            if (tags.count > 0) {
                self.tags = [NSSet setWithArray:tags];
            }
        }
        return YES;
    }
    
    return NO;
}

- (BOOL)handleSerializingProperty:(NSString *)propertyName value:(id)value destination:(NSMutableDictionary *)destination
{
    if ([propertyName isEqualToString:@"expiryTime"]) {
        if ([value isKindOfClass:[NSDate class]]) {
            NSNumber *d = @((int64_t) ([self.expiryTime timeIntervalSince1970] * 1000.0));
            destination[@"expiry_time"] = d;
        }
        return YES;

    } else if ([propertyName isEqualToString:@"triggerType"]) {
        if ([value isKindOfClass:[NSNumber class]]) {
            switch ([value integerValue]) {
                case PCFPushTriggerTypeEnter:
                    destination[@"trigger_type"] = @"enter";
                    break;
                case PCFPushTriggerTypeExit:
                    destination[@"trigger_type"] = @"exit";
                    break;
                default:
                    break;
            }
        }
        return YES;

    } else if ([propertyName isEqualToString:@"locations"]) {

        if ([value isKindOfClass:[NSArray class]]) {
            NSArray *locations = (NSArray *) value;
            if (locations.count > 0) {
                NSMutableArray *arr = [NSMutableArray array];
                for (PCFPushGeofenceLocation *location in locations) {
                    id l = [location pcfPushToFoundationType];
                    [arr addObject:l];
                }
                destination[@"locations"] = arr;
            }
        }
        return YES;

    } else if ([propertyName isEqualToString:@"tags"]) {

        if ([value isKindOfClass:[NSSet class]]) {
            NSSet *tags = (NSSet *) value;
            if (tags.count > 0) {
                destination[@"tags"] = tags.allObjects;
            }
        }
        return YES;
    }

    return NO;
}

@end
