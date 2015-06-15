//
// Created by DX173-XL on 15-05-14.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import "PCFPushGeofenceStatus.h"

NSString* PCF_PUSH_GEOFENCE_STATUS_UPDATE_NOTIFICATION = @"pivotal.push.geofence_status_update";

@interface PCFPushGeofenceStatus()

@property (readwrite) BOOL isError;
@property (readwrite) NSString *errorReason;
@property (readwrite) NSUInteger numberOfCurrentlyMonitoredGeofences;

@end

@implementation PCFPushGeofenceStatus

+ (instancetype) statusWithError:(BOOL)isError errorReason:(NSString*)errorReason number:(NSUInteger)numberOfCurrentlyMonitoringGeofences
{
    PCFPushGeofenceStatus *status = [[PCFPushGeofenceStatus alloc] init];
    status.isError = isError;
    if (errorReason && ![errorReason isKindOfClass:[NSNull class]]) {
        status.errorReason = errorReason;
    }
    status.numberOfCurrentlyMonitoredGeofences = numberOfCurrentlyMonitoringGeofences;
    return status;
}

+ (instancetype) emptyStatus
{
    PCFPushGeofenceStatus *status = [[PCFPushGeofenceStatus alloc] init];
    status.isError = NO;
    status.errorReason = nil;
    status.numberOfCurrentlyMonitoredGeofences = 0;
    return status;
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![[other class] isEqual:[self class]])
        return NO;

    return [self isEqualToStatus:other];
}

- (BOOL)isEqualToStatus:(PCFPushGeofenceStatus *)status {
    if (self == status)
        return YES;
    if (status == nil)
        return NO;
    if (self.isError != status.isError)
        return NO;
    if (self.errorReason != status.errorReason && ![self.errorReason isEqualToString:status.errorReason])
        return NO;
    if (self.numberOfCurrentlyMonitoredGeofences != status.numberOfCurrentlyMonitoredGeofences)
        return NO;
    return YES;
}

- (NSUInteger)hash {
    NSUInteger hash = (NSUInteger) self.isError;
    hash = hash * 31u + [self.errorReason hash];
    hash = hash * 31u + self.numberOfCurrentlyMonitoredGeofences;
    return hash;
}

- (NSString *)description
{
    if (self.errorReason) {
        return [NSString stringWithFormat:@"PCFPushGeofenceStatus: isError:%d errorReason:%@ numberOfCurrentlyMonitoredGeofences:%lu", self.isError, self.errorReason, (unsigned long)self.numberOfCurrentlyMonitoredGeofences];
    } else {
        return [NSString stringWithFormat:@"PCFPushGeofenceStatus: isError:%d numberOfCurrentlyMonitoredGeofences:%lu", self.isError, (unsigned long)self.numberOfCurrentlyMonitoredGeofences];
    }
}

@end