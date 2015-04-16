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
                                 PCF_STR_PROP(locations) : @"locations"
                                 };
    });
    return localToRemoteMapping;
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
            } else if ([value isEqualToString:@"enter_or_exit"]) {
                self.triggerType = PCFPushTriggerTypeEnterOrExit;
            }
        }
        return YES;

    } else if ([propertyName isEqualToString:@"locations"]) {
        if ([value isKindOfClass:[NSArray class]]) {
            NSArray *locations = (NSArray *) value;
            if (locations.count > 0) {
                NSMutableArray *arr = [NSMutableArray array];
                for (id location in locations) {
                    PCFPushGeofenceLocation *l = [PCFPushGeofenceLocation pcf_fromDictionary:location];
                    [arr addObject:l];
                }
                self.locations = arr;
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
                case PCFPushTriggerTypeEnterOrExit:
                    destination[@"trigger_type"] = @"enter_or_exit";
                    break;
                default:
                    break;
            }
        }
        return YES;

    } else if ([propertyName isEqualToString:@"locations"]) {

        if ([value isKindOfClass:[NSArray class]]) {
            NSArray *locations = (NSArray*)value;
            if (locations.count > 0) {
                NSMutableArray *arr = [NSMutableArray array];
                for (PCFPushGeofenceLocation *location in locations) {
                    id l = [location pcf_toFoundationType];
                    [arr addObject:l];
                }
                destination[@"locations"] = arr;
            }
        }
        return YES;
    }

    return NO;
}

@end
