//
// Created by DX181-XL on 15-04-16.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PCFPushGeofenceDataList;

@interface PCFPushGeofencePersistentStore : NSObject

- (void) reset;
- (PCFPushGeofenceDataList *)currentlyRegisteredGeofences;
- (void) saveRegisteredGeofences:(PCFPushGeofenceDataList *)geofences;

@end