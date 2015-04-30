//
// Created by DX181-XL on 15-04-16.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import "PCFPushGeofenceRegistrar.h"
#import "PCFPushGeofenceLocationMap.h"
#import "PCFPushGeofenceLocation.h"
#import "PCFPushDebug.h"
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

- (void)registerGeofences:(PCFPushGeofenceLocationMap *)geofencesToRegister
{
    [geofencesToRegister enumerateKeysAndObjectsUsingBlock:^(NSString *requestId, PCFPushGeofenceLocation *location, BOOL *stop) {
        CLLocationCoordinate2D center = CLLocationCoordinate2DMake(location.latitude, location.longitude);
        CLLocationDistance radius = location.radius;
        CLCircularRegion *region = [[CLCircularRegion alloc] initWithCenter:center radius:radius identifier:requestId];
        [self.locationManager startMonitoringForRegion:region];
    }];

    PCFPushLog(@"Number of monitored geofence locations: %d", geofencesToRegister.count);

    // TODO - write the registered geofences to the filesystem so that sample apps can see them and draw them.
}

- (void) reset
{
    // TODO - implement
}

@end