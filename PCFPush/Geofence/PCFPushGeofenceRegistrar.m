//
// Created by DX181-XL on 15-04-16.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import "PCFPushGeofenceRegistrar.h"
#import "PCFPushGeofenceLocationMap.h"
#import "PCFPushGeofenceDataList.h"
#import "PCFPushGeofenceLocation.h"
#import <CoreLocation/CoreLocation.h>

@interface PCFPushGeofenceRegistrar ()

@property (nonatomic) CLLocationManager *locationManager;

@end

@implementation PCFPushGeofenceRegistrar

- (instancetype) initWithLocationManager:(CLLocationManager*)locationManager
{
    self = [super init];
    if (self) {
        if (!locationManager) {
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"locationManager may not be nil" userInfo:nil];
        }
        self.locationManager = locationManager;
    }
    return self;
}

- (void) registerGeofences:(PCFPushGeofenceLocationMap*)geofencesToRegister geofenceDataList:(PCFPushGeofenceDataList*)geofenceDataList
{
    [geofencesToRegister enumerateKeysAndObjectsUsingBlock:^(int64_t geofenceId, int64_t locationId, PCFPushGeofenceLocation *location, BOOL *stop) {
        CLLocationCoordinate2D center = CLLocationCoordinate2DMake(location.latitude, location.longitude);
        CLLocationDistance radius = location.radius;
        NSString *identifier = @"PCF_7_66";
        CLCircularRegion *region = [[CLCircularRegion alloc] initWithCenter:center radius:radius identifier:identifier];
        [self.locationManager startMonitoringForRegion:region];
    }];
}

- (void) reset
{
    // TODO - implement
}

@end