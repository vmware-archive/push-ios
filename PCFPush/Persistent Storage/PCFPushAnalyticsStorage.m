//
// Created by DX173-XL on 15-07-20.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import <CoreData/CoreData.h>

#import "PCFPushAnalyticsStorage.h"
#import "PCFPushDebug.h"
#import "PCFPushAnalyticsEvent.h"

static NSString *const kDatabaseDirectoryName = @"PCFPushAnalyticsDB";
static NSString *const kDatabaseFileName = @"PCFPushAnalyticsDB.sqlite";

@interface PCFPushAnalyticsStorage ()

@property (nonatomic) NSURL *databaseURL;
@property (nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) NSManagedObjectModel *managedObjectModel;
@property (nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end

static PCFPushAnalyticsStorage *_sharedCoreDataManager;
static dispatch_once_t onceToken;

@implementation PCFPushAnalyticsStorage

#pragma mark - Class Methods

+ (instancetype)shared
{
    dispatch_once(&onceToken, ^{
        if (!_sharedCoreDataManager) {
            _sharedCoreDataManager = [[self alloc] init];
        }
    });

    return _sharedCoreDataManager;
}

// Used in unit tests
+ (void)setSharedManager:(PCFPushAnalyticsStorage *)manager
{
    onceToken = 0;
    _sharedCoreDataManager = manager;
}

// Used in unit tests
- (void)flushDatabase
{
    [_managedObjectContext lock];
    NSArray *stores = [_persistentStoreCoordinator persistentStores];
    for(NSPersistentStore *store in stores) {
        [_persistentStoreCoordinator removePersistentStore:store error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:store.URL.path error:nil];
    }
    [_managedObjectContext unlock];
    _managedObjectModel = nil;
    _managedObjectContext = nil;
    _persistentStoreCoordinator = nil;
}

#pragma mark - Core Data Setup

- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext) {
        return _managedObjectContext;
    }

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            [_managedObjectContext setPersistentStoreCoordinator:coordinator];
        });
    }
    return _managedObjectContext;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }

    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:self.databaseURL options:nil error:&error]) {
        PCFPushCriticalLog(@"Error adding persistent store: %@, %@", error, [error userInfo]);
        [[NSFileManager defaultManager] removeItemAtURL:self.databaseURL error:nil];
        [_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:self.databaseURL options:nil error:&error];
    }

    return _persistentStoreCoordinator;
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel) {
        return _managedObjectModel;
    }
    _managedObjectModel = [[NSManagedObjectModel alloc] init];
    NSString *entityName = NSStringFromClass([PCFPushAnalyticsEvent class]);
    NSEntityDescription *analyticEventEntity = [[NSEntityDescription alloc] init];
    [analyticEventEntity setName:entityName];
    [analyticEventEntity setManagedObjectClassName:entityName];
    [_managedObjectModel setEntities:@[analyticEventEntity]];

    NSAttributeDescription *statusDescription = [self attributeDescriptionWithName:NSStringFromSelector(@selector(status)) type:NSInteger16AttributeType optional:true];
    NSAttributeDescription *receiptIdDescription = [self attributeDescriptionWithName:NSStringFromSelector(@selector(receiptId)) type:NSStringAttributeType optional:true];
    NSAttributeDescription *eventTypeDescription = [self attributeDescriptionWithName:NSStringFromSelector(@selector(eventType)) type:NSStringAttributeType optional:true];
    NSAttributeDescription *eventTimeDescription = [self attributeDescriptionWithName:NSStringFromSelector(@selector(eventTime)) type:NSStringAttributeType optional:true];
    NSAttributeDescription *deviceUuidDescription = [self attributeDescriptionWithName:NSStringFromSelector(@selector(deviceUuid)) type:NSStringAttributeType optional:true];
    NSAttributeDescription *geofenceIdDescription = [self attributeDescriptionWithName:NSStringFromSelector(@selector(geofenceId)) type:NSStringAttributeType optional:true];
    NSAttributeDescription *locationIdDescription = [self attributeDescriptionWithName:NSStringFromSelector(@selector(locationId)) type:NSStringAttributeType optional:true];

    [analyticEventEntity setProperties:@[
            statusDescription,
            receiptIdDescription,
            eventTypeDescription,
            eventTimeDescription,
            deviceUuidDescription,
            geofenceIdDescription,
            locationIdDescription,
    ]];

    return _managedObjectModel;
}

- (NSAttributeDescription *)attributeDescriptionWithName:(NSString *)name
                                                    type:(NSAttributeType)attributeType
                                                optional:(BOOL)isOptional
{
    NSAttributeDescription *attribute = [[NSAttributeDescription alloc] init];
    attribute.name = name;
    attribute.attributeType = attributeType;
    attribute.optional = isOptional;
    return attribute;
}

- (NSURL *)databaseURL
{
    if (_databaseURL) {
        return _databaseURL;
    }

    NSFileManager *fileManager = [NSFileManager defaultManager];
    // TODO - shared this code with PCFPushGeofencePersistentStore?
    NSURL *libraryDirectoryURL = [[fileManager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *directoryURL = [libraryDirectoryURL URLByAppendingPathComponent:kDatabaseDirectoryName];

    if (![fileManager fileExistsAtPath:[directoryURL path]]) {
        NSError *error = nil;
        if (![fileManager createDirectoryAtURL:directoryURL withIntermediateDirectories:YES attributes:nil error:&error]) {
            PCFPushCriticalLog(@"Error creating database directory %@: %@", [directoryURL lastPathComponent], error);

        } else {
            NSError *error = nil;
            if (![directoryURL setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:&error]) {
                PCFPushCriticalLog(@"Error excluding %@ from backup %@", [directoryURL lastPathComponent], error);
            }
        }
    }
    _databaseURL = [directoryURL URLByAppendingPathComponent:kDatabaseFileName];
    return _databaseURL;
}

- (void)deleteManagedObjects:(NSArray *)managedObjects
{
    NSManagedObjectContext *context = self.managedObjectContext;
    [context performBlockAndWait:^{
        [managedObjects enumerateObjectsUsingBlock:^(NSManagedObject *managedObject, NSUInteger idx, BOOL *stop) {
            [context deleteObject:managedObject];
        }];

        if (context.deletedObjects.count > 0) {
            [context save:nil];
        }
    }];
}

- (NSArray *)events
{
    NSString *entityName = NSStringFromClass(PCFPushAnalyticsEvent.class);
    return [self managedObjectsWithEntityName:entityName];
}

- (NSArray *)eventsWithStatus:(PCFPushEventStatus)status
{
    NSString *entityName = NSStringFromClass(PCFPushAnalyticsEvent.class);
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"status == %u", status];
    return [self managedObjectsWithEntityName:entityName predicate:predicate];
}

- (NSArray*) unpostedEvents
{
    NSArray *notPostedEvents = [PCFPushAnalyticsStorage.shared eventsWithStatus:PCFPushEventStatusNotPosted];
    NSArray *postingErrorEvents = [PCFPushAnalyticsStorage.shared eventsWithStatus:PCFPushEventStatusPostingError];

    NSMutableArray *events = [NSMutableArray arrayWithCapacity:(notPostedEvents.count + postingErrorEvents.count)];
    if (notPostedEvents) {
        [events addObjectsFromArray:notPostedEvents];
    }
    if (postingErrorEvents) {
        [events addObjectsFromArray:postingErrorEvents];
    }

    return events;
}

- (NSArray *)managedObjectsWithEntityName:(NSString *)entityName
{
    return [self managedObjectsWithEntityName:entityName predicate:nil];
}

- (NSArray *) managedObjectsWithEntityName:(NSString*)entityName predicate:(NSPredicate*)predicate
{
    __block NSArray *managedObjects;
    [self.managedObjectContext performBlockAndWait:^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];

        request.predicate = predicate;

        if ([NSClassFromString(entityName) conformsToProtocol:@protocol(PCFSortDescriptors)]) {
            Class<PCFSortDescriptors> klass = (Class<PCFSortDescriptors>) NSClassFromString(entityName);
            request.sortDescriptors = [klass defaultSortDescriptors];
        }
        NSError *error;
        managedObjects = [self.managedObjectContext executeFetchRequest:request error:&error];
    }];
    return managedObjects;
}

- (void)setEventsStatus:(NSArray *)events status:(PCFPushEventStatus)status
{
    [self.managedObjectContext performBlockAndWait:^{

        for (PCFPushAnalyticsEvent *event in events) {
            event.status = @(status);
        }

        NSError *saveError;
        if (![self.managedObjectContext save:&saveError]) {
            PCFPushCriticalLog(@"Error setting %d analytics events to status %d: %@", events.count, status, saveError);
        }
    }];
}

@end