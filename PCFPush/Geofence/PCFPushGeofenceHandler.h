//
// Created by DX173-XL on 2015-05-04.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PCFPushGeofencePersistentStore;

@interface PCFPushGeofenceHandler : NSObject

+ (void)processRegion:(CLRegion *)region store:(PCFPushGeofencePersistentStore *)store state:(CLRegionState)state;

@end