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

static BOOL isItemExpired(PCFPushGeofenceData *geofence) {
    if (geofence.expiryTime == nil) {
        return YES;
    }

    NSDate *currentDate = [NSDate date];
    NSDate *laterDate = [currentDate laterDate:geofence.expiryTime];
    BOOL isItemExpired = laterDate == currentDate; // If the later date is the current date then the expiry date is in the past and so the item is expired
    return isItemExpired;
}

static BOOL isItemUpdated(PCFPushGeofenceData *geofence, PCFPushGeofenceResponseData *responseData) {
    for (PCFPushGeofenceData *responseDataGeofence in responseData.geofences) {
        if (responseDataGeofence.id == geofence.id) {
            return YES;
        }
    }
    return NO;
}

static BOOL isValidGeofenceFromStore(PCFPushGeofenceData *geofence, PCFPushGeofenceResponseData *responseData) {
    if ([responseData.deletedGeofenceIds containsObject:@(geofence.id)]) {
        return NO;
    }
    if (isItemExpired(geofence)) {
        return NO;
    }
    if (isItemUpdated(geofence, responseData)) {
        return NO;
    }
    return YES;
}

static BOOL isValidGeofenceFromResponseData(PCFPushGeofenceData *geofence) {
    if (geofence.data == nil) {
        return NO;
    }
    if (geofence.triggerType == PCFPushTriggerTypeUndefined) {
        return NO;
    }
    if (geofence.locations == nil || geofence.locations.count <= 0) {
        return NO;
    }
    if (isItemExpired(geofence)) {
        return NO;
    }
    return YES;
}

static void addValidGeofencesFromStore(PCFPushGeofenceDataList *requiredGeofences, PCFPushGeofenceDataList *storedGeofences, PCFPushGeofenceResponseData *responseData) {
    [storedGeofences enumerateKeysAndObjectsUsingBlock:^(int64_t id, PCFPushGeofenceData *geofence, BOOL *stop) {
        if (isValidGeofenceFromStore(geofence, responseData)) {
            requiredGeofences[@(id)] = geofence;
        }
    }];
}

static void addValidGeofencesFromUpdate(PCFPushGeofenceDataList *list, NSArray *update) {
    for (PCFPushGeofenceData *geofence in update) {
        if (isValidGeofenceFromResponseData(geofence)) {
            list[@(geofence.id)] = geofence;
        }
    }
}

static void addLocations(PCFPushGeofenceLocationMap *map, PCFPushGeofenceDataList *list) {
    [list enumerateKeysAndObjectsUsingBlock:^(int64_t id, PCFPushGeofenceData *geofence, BOOL *stop) {
        for(PCFPushGeofenceLocation *location in geofence.locations) {
            [map put:geofence location:location];
        }
    }];
}

static BOOL hasDataToPersist(PCFPushGeofenceResponseData *responseData, PCFPushGeofenceDataList *storedGeofences) {
    return (storedGeofences != nil && storedGeofences.count > 0) || (responseData.geofences != nil && responseData.geofences.count > 0);
}

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

    if (!hasDataToPersist(responseData, currentlyRegisteredGeofences)) {
        return;
    }

    PCFPushGeofenceDataList *geofencesToStore = [[PCFPushGeofenceDataList alloc] init];
    PCFPushGeofenceLocationMap *geofencesToRegister = [[PCFPushGeofenceLocationMap alloc] init];

    addValidGeofencesFromStore(geofencesToStore, currentlyRegisteredGeofences, responseData);
    addValidGeofencesFromUpdate(geofencesToStore, responseData.geofences);

    addLocations(geofencesToRegister, geofencesToStore);

    [self.registrar registerGeofences:geofencesToRegister geofenceDataList:geofencesToStore];
    [self.store saveRegisteredGeofences:geofencesToStore];

}

@end
