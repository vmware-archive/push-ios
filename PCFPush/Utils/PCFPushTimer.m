//
// Created by DX173-XL on 15-06-10.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "PCFPushTimer.h"
#import "PCFPushDebug.h"

NSInteger pcfPushTimerReferenceCounter = 0;

@implementation PCFPushTimer

+ (void)startLocationUpdateTimer:(CLLocationManager *)locationManager
{
    if (pcfPushTimerReferenceCounter <= 0) {
        pcfPushTimerReferenceCounter = 1;

        PCFPushLog(@"Starting to track device location. Starting timer.");
        pcfPushTimerReferenceCounter = YES;
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
        locationManager.distanceFilter = 10; // meters
        [locationManager startUpdatingLocation];
    } else {
        pcfPushTimerReferenceCounter += 1;
        PCFPushLog(@"No need to start tracking device location here since it is already happening. Starting timer. Timer reference count is now %d.", pcfPushTimerReferenceCounter);
    }
    [self startTimer:locationManager];
}

+ (void) startTimer:(CLLocationManager *)locationManager
{
    __weak CLLocationManager *lm = locationManager;

    // TODO - decide if 60 seconds is enough time to wait for an accurate location.

    dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60.0 * NSEC_PER_SEC)); // 60 seconds
    dispatch_after(when, dispatch_get_main_queue(), ^{
        [PCFPushTimer handleStop:lm reason:@"timer elapsed"];
    });
}

+ (void)stopLocationUpdateTimer:(CLLocationManager *)locationManager
{
    [PCFPushTimer handleStop:locationManager reason:@"accuracy reached"];
}

+ (void)handleStop:(__weak CLLocationManager *)locationManager reason:(NSString*)reason
{
    if (pcfPushTimerReferenceCounter > 1) {
        pcfPushTimerReferenceCounter -= 1;
        PCFPushLog(@"Location tracking timer will remain active. Timer reference count is now %d.", pcfPushTimerReferenceCounter);

    } else if (pcfPushTimerReferenceCounter == 1) {
        pcfPushTimerReferenceCounter = 0;
        PCFPushLog(@"Stopping tracking device location (%@)", reason);

        if (locationManager) {
            [locationManager stopUpdatingLocation];
        }

    } else { // pcfPushTimerReferenceCounter < 1
        PCFPushLog(@"Location tracking timer has elapsed and location updates have already been stopped.");
    }
}

@end