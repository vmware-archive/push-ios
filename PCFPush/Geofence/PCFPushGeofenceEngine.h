//
// Created by DX181-XL on 15-04-15.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PCFPushGeofenceResponseData;
@class PCFPushGeofenceRegistrar;
@class PCFPushGeofencePersistentStore;
@class PCFPushGeofenceLocationMap;

@interface PCFPushGeofenceEngine : NSObject

- (id)initWithRegistrar:(PCFPushGeofenceRegistrar *)registrar store:(PCFPushGeofencePersistentStore *)store;

- (void)processResponseData:(PCFPushGeofenceResponseData *)responseData withTimestamp:(int64_t)timestamp withTags:(NSSet *)tags;

- (void)clearLocations:(PCFPushGeofenceLocationMap *)locationsToClear withTags:(NSSet *)subscribedTags;

- (void)reregisterCurrentLocationsWithTags:(NSSet*)subscribedTags;

@end