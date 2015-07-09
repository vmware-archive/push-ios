//
// Created by DX181-XL on 15-04-15.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "PCFPushGeofenceEngine.h"
#import "PCFPushGeofenceResponseData.h"
#import "PCFPushGeofenceRegistrar.h"
#import "PCFPushGeofencePersistentStore.h"
#import "PCFPushGeofenceLocationMap.h"
#import "PCFPushGeofenceData.h"
#import "PCFPushGeofenceDataList.h"
#import "PCFPushGeofenceUtil.h"
#import "PCFPushGeofenceLocation.h"
#import "PCFPushDebug.h"
#import "PCFTagsHelper.h"
#import "PCFPushPersistentStorage.h"

static BOOL shouldSelectGeofenceForRegistration(PCFPushGeofenceData *geofence, NSSet *subscribedTags);

@interface PCFPushGeofenceEngine ()

@property (nonatomic) PCFPushGeofenceRegistrar *registrar;
@property (nonatomic) PCFPushGeofencePersistentStore *store;

@end

static BOOL isItemUpdated(PCFPushGeofenceData *geofence, PCFPushGeofenceResponseData *responseData)
{
    for (PCFPushGeofenceData *responseDataGeofence in responseData.geofences) {
        if (responseDataGeofence.id == geofence.id) {
            return YES;
        }
    }
    return NO;
}

static BOOL geofenceHasInvalidLocations(NSArray *array)
{
    // Note - a geofence can have several locations.  If *any* of those locations has a invalid set of coordinates then the whole geofence is considered invalid.
    for (PCFPushGeofenceLocation *location in array) {
        CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(location.latitude, location.longitude);
        if (!CLLocationCoordinate2DIsValid(coord)) {
            PCFPushCriticalLog(@"Location with id %lld has invalid coordinates %f, %f", location.id, location.latitude, location.longitude);
            return YES;
        } else if (location.radius < 10.0) {
            PCFPushCriticalLog(@"Location with id %lld has invalid radius value %f", location.radius);
            return YES;
        }
    }
    return NO;
}

static BOOL isValidGeofenceFromStore(PCFPushGeofenceData *geofence, PCFPushGeofenceResponseData *responseData)
{
    if ([responseData.deletedGeofenceIds containsObject:@(geofence.id)]) {
        return NO;
    }
    if (pcfPushIsItemExpired(geofence)) {
        return NO;
    }
    if (isItemUpdated(geofence, responseData)) {
        return NO;
    }
    if (geofenceHasInvalidLocations(geofence.locations)) {
        return NO;
    }
    return YES;
}

static BOOL isValidGeofenceFromResponseData(PCFPushGeofenceData *geofence)
{
    if (geofence.data == nil) {
        return NO;
    }
    if (geofence.data[@"ios"] == nil) {
        return NO;
    }
    if (geofence.triggerType == PCFPushTriggerTypeUndefined) {
        return NO;
    }
    if (geofence.locations == nil || geofence.locations.count <= 0) {
        return NO;
    }
    if (geofenceHasInvalidLocations(geofence.locations)) {
        return NO;
    }
    if (pcfPushIsItemExpired(geofence)) {
        return NO;
    }
    return YES;
}

static void addValidGeofencesFromStore(PCFPushGeofenceDataList *requiredGeofences, PCFPushGeofenceDataList *storedGeofences, PCFPushGeofenceResponseData *responseData)
{
    [storedGeofences enumerateKeysAndObjectsUsingBlock:^(int64_t id, PCFPushGeofenceData *geofence, BOOL *stop) {
        if (isValidGeofenceFromStore(geofence, responseData)) {
            requiredGeofences[@(id)] = geofence;
        }
    }];
}

static void addValidGeofencesFromUpdate(PCFPushGeofenceDataList *list, NSArray *update)
{
    for (PCFPushGeofenceData *geofence in update) {
        if (isValidGeofenceFromResponseData(geofence)) {
            list[@(geofence.id)] = geofence;
        }
    }
}

static void selectGeofencesToRegister(PCFPushGeofenceLocationMap *geofencesToRegister, PCFPushGeofenceDataList *geofencesToStore, NSSet *subscribedTags)
{
    [geofencesToStore enumerateKeysAndObjectsUsingBlock:^(int64_t id, PCFPushGeofenceData *geofence, BOOL *stop) {
        for(PCFPushGeofenceLocation *location in geofence.locations) {
            if (shouldSelectGeofenceForRegistration(geofence, subscribedTags)) {
                [geofencesToRegister put:geofence location:location];
            }
        }
    }];
}

static BOOL shouldSelectGeofenceForRegistration(PCFPushGeofenceData *geofence, NSSet *subscribedTags)
{
    if (geofence.tags && geofence.tags.count > 0) {
        if (subscribedTags) {
            BOOL intersects = [subscribedTags intersectsSet:pcfPushLowercaseTags(geofence.tags)];
            if (!intersects) {
                PCFPushLog(@"Ignoring geofence %lld. Not subscribed to any of its tags.", geofence.id);
            }
            return intersects;
        } else {
            PCFPushLog(@"Ignoring geofence %lld. Not subscribed to any tags.", geofence.id);
            return NO;
        }
    } else {
        return YES;
    }
}

static BOOL hasDataToPersist(PCFPushGeofenceResponseData *responseData, PCFPushGeofenceDataList *storedGeofences)
{
    return (storedGeofences != nil && storedGeofences.count > 0) || (responseData.geofences != nil && responseData.geofences.count > 0);
}

static void keepGeofenceLocation(int64_t geofenceId,
        PCFPushGeofenceData *geofenceToKeep,
        PCFPushGeofenceLocation *locationToKeep,
        PCFPushGeofenceDataList *geofencesToStore,
        PCFPushGeofenceLocationMap *geofencesToRegister,
        NSString *requestId,
        NSSet *subscribedTags)
{
    if (shouldSelectGeofenceForRegistration(geofenceToKeep, subscribedTags)) {
        geofencesToRegister[requestId] = locationToKeep;
    }

    PCFPushGeofenceData *newCopy = geofencesToStore[@(geofenceId)];
    if (!newCopy) {
        newCopy = [geofenceToKeep newCopyWithoutLocations];
        NSMutableArray *newLocations = [NSMutableArray array];
        [newLocations addObject:locationToKeep];
        newCopy.locations = newLocations;
        geofencesToStore[@(geofenceId)] = newCopy;
    } else {
        NSMutableArray *newLocations = (NSMutableArray *)newCopy.locations;
        [newLocations addObject:locationToKeep];
    }
}

static void filterClearedLocations(PCFPushGeofenceLocationMap *locationsToClear, PCFPushGeofenceDataList *storedGeofences, PCFPushGeofenceDataList *geofencesToStore, PCFPushGeofenceLocationMap *geofencesToRegister, NSSet *subscribedTags)
{
    [storedGeofences enumerateKeysAndObjectsUsingBlock:^(int64_t geofenceId, PCFPushGeofenceData *geofence, BOOL *stop) {

        if (!geofence || !geofence.locations || geofence.locations.count <= 0) {
            return;
        }

        for (PCFPushGeofenceLocation *location in geofence.locations) {
            NSString *requestId = pcfPushRequestIdWithGeofenceId(geofenceId, location.id);
            if (!locationsToClear[requestId]) {
                keepGeofenceLocation(geofenceId, geofence, location, geofencesToStore, geofencesToRegister, requestId, subscribedTags);
            }
        }
    }];
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

- (void)processResponseData:(PCFPushGeofenceResponseData *)responseData withTimestamp:(int64_t)timestamp withTags:(NSSet *)tags
{
    if (timestamp == 0L) {
        PCFPushLog(@"Resetting currently stored and monitored geofences (if there are any).");
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
        currentlyRegisteredGeofences = [PCFPushGeofenceDataList list];
    }

    if (!hasDataToPersist(responseData, currentlyRegisteredGeofences)) {
        PCFPushLog(@"Geofence engine exiting, no data to persist");
        return;
    }

    PCFPushGeofenceDataList *geofencesToStore = [PCFPushGeofenceDataList list];
    PCFPushGeofenceLocationMap *geofencesToRegister = [PCFPushGeofenceLocationMap map];

    addValidGeofencesFromStore(geofencesToStore, currentlyRegisteredGeofences, responseData);
    addValidGeofencesFromUpdate(geofencesToStore, responseData.geofences);

    selectGeofencesToRegister(geofencesToRegister, geofencesToStore, tags);

    [self.registrar registerGeofences:geofencesToRegister list:geofencesToStore];
    [self.store saveRegisteredGeofences:geofencesToStore];
}

- (void)clearLocations:(PCFPushGeofenceLocationMap *)locationsToClear withTags:(NSSet *)subscribedTags
{
    if (!locationsToClear || locationsToClear.count <= 0) {
        return;
    }

    PCFPushGeofenceDataList *storedGeofences = [self.store currentlyRegisteredGeofences];
    PCFPushGeofenceDataList *geofencesToStore = [PCFPushGeofenceDataList list];
    PCFPushGeofenceLocationMap *geofencesToRegister = [PCFPushGeofenceLocationMap map];

    filterClearedLocations(locationsToClear, storedGeofences, geofencesToStore, geofencesToRegister, subscribedTags);

    [self.registrar registerGeofences:geofencesToRegister list:geofencesToStore];
    [self.store saveRegisteredGeofences:geofencesToStore];
}

- (void)reregisterCurrentLocationsWithTags:(NSSet*)subscribedTags
{
    PCFPushGeofenceDataList *storedGeofences = [self.store currentlyRegisteredGeofences];

    PCFPushGeofenceLocationMap *geofencesToRegister = [PCFPushGeofenceLocationMap map];
    selectGeofencesToRegister(geofencesToRegister, storedGeofences, subscribedTags);

    [self.registrar registerGeofences:geofencesToRegister list:storedGeofences];
}

@end
