//
// Created by DX181-XL on 15-04-15.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import "PCFPushGeofenceEngine.h"
#import "PCFPushGeofenceResponseData.h"
#import "PCFPushGeofenceRegistrar.h"
#import "PCFPushGeofencePersistentStore.h"
#import "PCFPushGeofenceLocationMap.h"
#import "PCFPushGeofenceDataList.h"
#import "PCFPushGeofenceData.h"
#import "PCFPushGeofenceLocation.h"

@interface PCFPushGeofenceEngine ()

@property (nonatomic) PCFPushGeofenceRegistrar *registrar;
@property (nonatomic) PCFPushGeofencePersistentStore *store;

@end

@implementation PCFPushGeofenceEngine

- (id)initWithRegistrar:(PCFPushGeofenceRegistrar *)registrar store:(PCFPushGeofencePersistentStore *)store
{
    self = [super init];
    if (self) {
        if (!registrar) {
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"registrar may not be nil" userInfo:nil];
        }
        if (!store) {
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"store may not be nil" userInfo:nil];
        }
        self.store = store;
        self.registrar = registrar;
    }
    return self;
}

- (void) processResponseData:(PCFPushGeofenceResponseData*)responseData withTimestamp:(int64_t)timestamp
{
    if (timestamp == 0L) {
        [self.registrar reset];
        [self.store reset];
    }

    if (!responseData) {
        return;
    }

    PCFPushGeofenceDataList *currentlyRegisteredGeofences;

    if (timestamp != 0L) {
        currentlyRegisteredGeofences = [self.store currentlyRegisteredGeofences];
    } else {
        currentlyRegisteredGeofences = [[PCFPushGeofenceDataList alloc] init];
    }

    if (![self hasDataToPersist:responseData storedGeofences:currentlyRegisteredGeofences]) {
        return;
    }

    PCFPushGeofenceDataList *geofencesToStore = [[PCFPushGeofenceDataList alloc] init];
    PCFPushGeofenceLocationMap *geofencesToRegister = [[PCFPushGeofenceLocationMap alloc] init];

    [self addValidGeofences:geofencesToStore fromStore:currentlyRegisteredGeofences withResponseData:responseData];
    [self addValidGeofences:geofencesToStore fromUpdate:responseData.geofences];

    [self addLocations:geofencesToRegister fromList:geofencesToStore];

    [self.registrar registerGeofences:geofencesToRegister geofenceDataList:geofencesToStore];
    [self.store saveRegisteredGeofences:geofencesToStore];

}

- (void)addValidGeofences:(PCFPushGeofenceDataList *)requiredGeofences fromStore:(PCFPushGeofenceDataList *)storedGeofences withResponseData:(PCFPushGeofenceResponseData *)responseData
{
    // TODO - filter items expired items, deleted items, and items with no data
    [storedGeofences enumerateKeysAndObjectsUsingBlock:^(int64_t id, PCFPushGeofenceData *geofence, BOOL *stop) {
        requiredGeofences[@(id)] = geofence;
    }];
}

- (void)addValidGeofences:(PCFPushGeofenceDataList *)list fromUpdate:(NSArray *)update
{
    // TODO - filter items expired item, items with no locations, items with no trigger types and items with no data
    for (PCFPushGeofenceData *geofence in update) {
        list[@(geofence.id)] = geofence;
    }
}

- (void)addLocations:(PCFPushGeofenceLocationMap *)map fromList:(PCFPushGeofenceDataList *)list
{
    [list enumerateKeysAndObjectsUsingBlock:^(int64_t id, PCFPushGeofenceData *geofence, BOOL *stop) {
        for(PCFPushGeofenceLocation *location in geofence.locations) {
            [map put:geofence location:location];
        }
    }];
}

- (BOOL) hasDataToPersist:(PCFPushGeofenceResponseData *) responseData storedGeofences:(PCFPushGeofenceDataList *)storedGeofences
{
    return (storedGeofences != nil && storedGeofences.count > 0) ||
            (responseData.geofences != nil && responseData.geofences.count > 0);
}

@end