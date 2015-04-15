//
//  PCFPushGeofenceLocation.m
//  PCFPush
//
//  Created by DX181-XL on 2015-04-14.
//  Copyright (c) 2015 Pivotal. All rights reserved.
//

#import "PCFPushGeofenceLocation.h"

@implementation PCFPushGeofenceLocation

+ (NSDictionary *)localToRemoteMapping
{
    static NSDictionary *localToRemoteMapping;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        localToRemoteMapping = @{
                                 PCF_STR_PROP(id) : @"id",
                                 PCF_STR_PROP(name) : @"name",
                                 PCF_STR_PROP(latitude) : @"lat",
                                 PCF_STR_PROP(longitude) : @"long",
                                 PCF_STR_PROP(radius) : @"rad"
                                 };
    });
    return localToRemoteMapping;
}

@end
