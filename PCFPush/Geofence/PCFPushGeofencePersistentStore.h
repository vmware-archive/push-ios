//
// Created by DX181-XL on 15-04-16.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PCFPushGeofenceDataList;
@class PCFPushGeofenceData;

@interface PCFPushGeofencePersistentStore : NSObject

- (instancetype) initWithFileManager:(NSFileManager*)fileManager;
- (PCFPushGeofenceDataList *)currentlyRegisteredGeofences;
- (void) saveRegisteredGeofences:(PCFPushGeofenceDataList *)geofences;
- (id)objectForKeyedSubscript:(id <NSCopying>)key;
- (void) reset;

@end