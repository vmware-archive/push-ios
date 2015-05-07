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

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![[other class] isEqual:[self class]])
        return NO;

    return [self isEqualToLocation:other];
}

- (BOOL)isEqualToLocation:(PCFPushGeofenceLocation *)location {
    if (self == location)
        return YES;
    if (location == nil)
        return NO;
    if (self.id != location.id)
        return NO;
    if (self.name != location.name && ![self.name isEqualToString:location.name])
        return NO;
    if (self.latitude != location.latitude)
        return NO;
    if (self.longitude != location.longitude)
        return NO;
    if (self.radius != location.radius)
        return NO;
    return YES;
}

- (NSUInteger)hash {
    NSUInteger hash = (NSUInteger) self.id;
    hash = hash * 31u + [self.name hash];
    hash = hash * 31u + [[NSNumber numberWithDouble:self.latitude] hash];
    hash = hash * 31u + [[NSNumber numberWithDouble:self.longitude] hash];
    hash = hash * 31u + [[NSNumber numberWithDouble:self.radius] hash];
    return hash;
}

@end
