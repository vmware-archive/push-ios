//
// Created by DX173-XL on 15-06-10.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CLLocationManager;

extern NSInteger pcfPushTimerReferenceCounter;

@interface PCFPushTimer : NSObject

+ (void) startLocationUpdateTimer:(CLLocationManager *)locationManager;
+ (void) stopLocationUpdateTimer:(CLLocationManager *)locationManager;

@end