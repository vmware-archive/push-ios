//
// Created by DX173-XL on 15-07-20.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import "PCFPushAnalyticsEvent.h"

const struct EventRemoteAttributes {
    PCF_STRUCT_STRING *receiptId;
    PCF_STRUCT_STRING *eventType;
    PCF_STRUCT_STRING *eventTime;
    PCF_STRUCT_STRING *deviceUuid;
    PCF_STRUCT_STRING *geofenceId;
    PCF_STRUCT_STRING *locationId;
} EventRemoteAttributes;

const struct EventRemoteAttributes EventRemoteAttributes = {
        .receiptId  = @"receiptId",
        .eventType  = @"eventType",
        .eventTime  = @"eventTime",
        .deviceUuid = @"deviceUuid",
        .geofenceId = @"geofenceId",
        .locationId = @"locationId",
};

@implementation PCFPushAnalyticsEvent

@dynamic status; // the status field is not serialized for transmission to the remote server
@dynamic receiptId;
@dynamic eventType;
@dynamic eventTime;
@dynamic deviceUuid;
@dynamic geofenceId;
@dynamic locationId;

#pragma mark - PCFSortDescriptors Protocol

+ (NSArray *)defaultSortDescriptors
{
    return @[[NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(eventTime)) ascending:NO]];
}

#pragma mark - PCFMapping Protocol

+ (NSDictionary *)localToRemoteMapping
{
    static NSDictionary *localToRemoteMapping;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        localToRemoteMapping = @{
                PCF_STR_PROP(receiptId)  : EventRemoteAttributes.receiptId,
                PCF_STR_PROP(eventType)  : EventRemoteAttributes.eventType,
                PCF_STR_PROP(eventTime)  : EventRemoteAttributes.eventTime,
                PCF_STR_PROP(deviceUuid) : EventRemoteAttributes.deviceUuid,
                PCF_STR_PROP(geofenceId) : EventRemoteAttributes.geofenceId,
                PCF_STR_PROP(locationId) : EventRemoteAttributes.locationId,
        };
    });

    return localToRemoteMapping;
}

@end