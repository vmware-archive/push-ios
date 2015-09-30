//
// Created by DX173-XL on 15-07-20.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import <CoreData/CoreData.h>

#import "PCFPushAnalyticsStorage.h"
#import "PCFPushDebug.h"
#import "PCFPushAnalyticsEvent.h"

static NSUInteger _numberOfMigrations = 0;
static NSString *const kDatabaseDirectoryName = @"PCFPushAnalyticsDB";
static NSString *const kDatabaseFileName = @"PCFPushAnalyticsDB.sqlite";
static NSString *const kTemporaryDatabaseFileName = @"PCFPushAnalyticsDB.TEMP.sqlite"; // Used during migrations

@interface PCFPushAnalyticsStorage ()

@property (nonatomic) NSURL *databaseURL;
@property (nonatomic) NSURL *tempDatabaseURL;
@property (nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) NSManagedObjectModel *managedObjectModel;
@property (nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end

static PCFPushAnalyticsStorage *_sharedCoreDataManager;
static dispatch_once_t onceToken;

@implementation PCFPushAnalyticsStorage

#pragma mark - Life cycle methods

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
- (void)resetDatabase:(BOOL)keepDatabaseFile
{
    if (!keepDatabaseFile) {
        [_managedObjectContext lock];
        NSArray *stores = [_persistentStoreCoordinator persistentStores];
        for(NSPersistentStore *store in stores) {
            [_persistentStoreCoordinator removePersistentStore:store error:nil];
            [[NSFileManager defaultManager] removeItemAtPath:store.URL.path error:nil];
        }
        [_managedObjectContext unlock];
    }
    _managedObjectModel = nil;
    _managedObjectContext = nil;
    _persistentStoreCoordinator = nil;
    _numberOfMigrations = 0;
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
    
    if ([PCFPushAnalyticsStorage isMigrationNecessaryForStore:self.databaseURL destinationModel:self.managedObjectModel]) {
        if (![PCFPushAnalyticsStorage migrateStore:self.databaseURL tempStore:self.tempDatabaseURL destinationModel:PCFPushAnalyticsStorage.newestManagedObjectModel]) {
            _persistentStoreCoordinator = nil;
            return _persistentStoreCoordinator;
        }
    }
    
    NSDictionary *options = @{ NSSQLitePragmasOption: @{@"journal_mode": @"DELETE"} };
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:self.databaseURL options:options error:&error]) {
        PCFPushCriticalLog(@"Error adding persistent store: %@, %@", error, [error userInfo]);
        [[NSFileManager defaultManager] removeItemAtURL:self.databaseURL error:nil];
        if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:self.databaseURL options:options error:&error]) {
            _persistentStoreCoordinator = nil;
            return _persistentStoreCoordinator;
        }
    }

    return _persistentStoreCoordinator;
}

#pragma mark - Model helper methods

- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel) {
        return _managedObjectModel;
    }
    
    _managedObjectModel = [PCFPushAnalyticsStorage newestManagedObjectModel];
    return _managedObjectModel;
}

+ (NSManagedObjectModel *)newestManagedObjectModel
{
    return [PCFPushAnalyticsStorage managedObjectModelV2];
}

+ (NSArray<NSManagedObjectModel *> *)allManagedObjectModels
{
    return @[ PCFPushAnalyticsStorage.managedObjectModelV1, PCFPushAnalyticsStorage.managedObjectModelV2 ];
}

+ (NSManagedObjectModel *)managedObjectModelV1
{
    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] init];
    NSString *entityName = NSStringFromClass([PCFPushAnalyticsEvent class]);
    NSEntityDescription *analyticEventEntity = [[NSEntityDescription alloc] init];
    [analyticEventEntity setName:entityName];
    [analyticEventEntity setManagedObjectClassName:entityName];
    [model setEntities:@[analyticEventEntity]];

    NSAttributeDescription *statusDescription = [PCFPushAnalyticsStorage attributeDescriptionWithName:NSStringFromSelector(@selector(status)) type:NSInteger16AttributeType optional:true];
    NSAttributeDescription *receiptIdDescription = [PCFPushAnalyticsStorage attributeDescriptionWithName:NSStringFromSelector(@selector(receiptId)) type:NSStringAttributeType optional:true];
    NSAttributeDescription *eventTypeDescription = [PCFPushAnalyticsStorage attributeDescriptionWithName:NSStringFromSelector(@selector(eventType)) type:NSStringAttributeType optional:true];
    NSAttributeDescription *eventTimeDescription = [PCFPushAnalyticsStorage attributeDescriptionWithName:NSStringFromSelector(@selector(eventTime)) type:NSStringAttributeType optional:true];
    NSAttributeDescription *deviceUuidDescription = [PCFPushAnalyticsStorage attributeDescriptionWithName:NSStringFromSelector(@selector(deviceUuid)) type:NSStringAttributeType optional:true];
    NSAttributeDescription *geofenceIdDescription = [PCFPushAnalyticsStorage attributeDescriptionWithName:NSStringFromSelector(@selector(geofenceId)) type:NSStringAttributeType optional:true];
    NSAttributeDescription *locationIdDescription = [PCFPushAnalyticsStorage attributeDescriptionWithName:NSStringFromSelector(@selector(locationId)) type:NSStringAttributeType optional:true];

    [analyticEventEntity setProperties:@[
            statusDescription,
            receiptIdDescription,
            eventTypeDescription,
            eventTimeDescription,
            deviceUuidDescription,
            geofenceIdDescription,
            locationIdDescription,
    ]];

    return model;
}

+ (NSManagedObjectModel *)managedObjectModelV2
{
    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] init];
    NSString *entityName = NSStringFromClass([PCFPushAnalyticsEvent class]);
    NSEntityDescription *analyticEventEntity = [[NSEntityDescription alloc] init];
    [analyticEventEntity setName:entityName];
    [analyticEventEntity setManagedObjectClassName:entityName];
    [model setEntities:@[analyticEventEntity]];
    
    NSAttributeDescription *statusDescription = [PCFPushAnalyticsStorage attributeDescriptionWithName:NSStringFromSelector(@selector(status)) type:NSInteger16AttributeType optional:true];
    NSAttributeDescription *receiptIdDescription = [PCFPushAnalyticsStorage attributeDescriptionWithName:NSStringFromSelector(@selector(receiptId)) type:NSStringAttributeType optional:true];
    NSAttributeDescription *eventTypeDescription = [PCFPushAnalyticsStorage attributeDescriptionWithName:NSStringFromSelector(@selector(eventType)) type:NSStringAttributeType optional:true];
    NSAttributeDescription *eventTimeDescription = [PCFPushAnalyticsStorage attributeDescriptionWithName:NSStringFromSelector(@selector(eventTime)) type:NSStringAttributeType optional:true];
    NSAttributeDescription *deviceUuidDescription = [PCFPushAnalyticsStorage attributeDescriptionWithName:NSStringFromSelector(@selector(deviceUuid)) type:NSStringAttributeType optional:true];
    NSAttributeDescription *geofenceIdDescription = [PCFPushAnalyticsStorage attributeDescriptionWithName:NSStringFromSelector(@selector(geofenceId)) type:NSStringAttributeType optional:true];
    NSAttributeDescription *locationIdDescription = [PCFPushAnalyticsStorage attributeDescriptionWithName:NSStringFromSelector(@selector(locationId)) type:NSStringAttributeType optional:true];
    NSAttributeDescription *sdkVersionDescription = [PCFPushAnalyticsStorage attributeDescriptionWithName:NSStringFromSelector(@selector(sdkVersion)) type:NSStringAttributeType optional:true];  // NEW in V2
    
    [analyticEventEntity setProperties:@[
                                         statusDescription,
                                         receiptIdDescription,
                                         eventTypeDescription,
                                         eventTimeDescription,
                                         deviceUuidDescription,
                                         geofenceIdDescription,
                                         locationIdDescription,
                                         sdkVersionDescription,
                                         ]];
    
    return model;
}

+ (NSAttributeDescription *)attributeDescriptionWithName:(NSString *)name
                                                    type:(NSAttributeType)attributeType
                                                optional:(BOOL)isOptional
{
    NSAttributeDescription *attribute = [[NSAttributeDescription alloc] init];
    attribute.name = name;
    attribute.attributeType = attributeType;
    attribute.optional = isOptional;
    return attribute;
}

#pragma mark - File helper methods

- (NSURL *)databaseURL
{
    if (_databaseURL) {
        return _databaseURL;
    }
    
    _databaseURL = [self.databaseDirectoryURL URLByAppendingPathComponent:kDatabaseFileName];
    return _databaseURL;
}

- (NSURL *)tempDatabaseURL
{
    if (_tempDatabaseURL) {
        return _tempDatabaseURL;
    }
    
    _tempDatabaseURL = [self.databaseDirectoryURL URLByAppendingPathComponent:kTemporaryDatabaseFileName];
    return _tempDatabaseURL;
    
}

- (NSURL *)databaseDirectoryURL
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
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
    return directoryURL;
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

#pragma mark - Query helper methods

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

#pragma mark - Migration helper methods

+ (BOOL) isMigrationNecessaryForStore:(NSURL*)storeUrl destinationModel:(NSManagedObjectModel*)destinationModel
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:storeUrl.path]) {
        PCFPushLog(@"Database source file not found, skipping migration. (NOT an error)");
        return NO;
    }
    
    NSError *error = nil;
    NSDictionary *sourceMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType URL:storeUrl error:&error];
    if ([destinationModel isConfiguration:nil compatibleWithStoreMetadata:sourceMetadata]) {
        PCFPushLog(@"Database source is already compatible, skipped migration");
        return NO;
    }
    return YES;
}

+ (NSManagedObjectModel*) sourceModelForStore:(NSURL*)storeUrl
{
    NSError *error;
    NSDictionary *sourceMetadata = [NSPersistentStoreCoordinator
                                    metadataForPersistentStoreOfType:NSSQLiteStoreType
                                    URL:storeUrl
                                    error:&error];
    
    if (error) {
        PCFPushCriticalLog(@"ERROR: Unable to get source metadata for store '%@': %@", storeUrl.absoluteString, error);
        return nil;
    }
    
    NSManagedObjectModel *sourceModel = [NSManagedObjectModel modelByMergingModels:PCFPushAnalyticsStorage.allManagedObjectModels forStoreMetadata:sourceMetadata];
    if (!sourceModel) {
        PCFPushCriticalLog(@"ERROR: Unable to get source object model for store %@'", storeUrl.absoluteString);
        return nil;
    }
    
    return sourceModel;
}

+ (BOOL) migrateStore:(NSURL*)sourceStore tempStore:(NSURL*)tempStore destinationModel:(NSManagedObjectModel*)destinationModel
{
    BOOL success = NO;
    
    NSError *error = nil;
    NSManagedObjectModel *sourceModel = [PCFPushAnalyticsStorage sourceModelForStore:sourceStore];
    if (!sourceModel) {
        return NO;
    }
    
    NSMappingModel *mappingModel = [NSMappingModel inferredMappingModelForSourceModel:sourceModel destinationModel:destinationModel error:&error];
    
    if (mappingModel) {
        NSMigrationManager *migrationManager = [[NSMigrationManager alloc] initWithSourceModel:sourceModel destinationModel:destinationModel];
        
        NSURL *destinationURL = tempStore;
        
        success = [migrationManager migrateStoreFromURL:sourceStore
                                                   type:NSSQLiteStoreType
                                                options:nil
                                       withMappingModel:mappingModel
                                       toDestinationURL:destinationURL
                                        destinationType:NSSQLiteStoreType
                                     destinationOptions:nil
                                                  error:&error];
        if (success) {
            _numberOfMigrations += 1;
            if ([PCFPushAnalyticsStorage replaceStore:sourceStore withStore:destinationURL]) {
                PCFPushLog(@"Database successfully migrated %@ to the latest model", sourceStore.path);
            }
        } else {
            PCFPushCriticalLog(@"ERROR: Database migration failure: %@",error);
        }
    } else {
        PCFPushCriticalLog(@"ERROR: Database migration inferring mapping model failure: %@", error);
    }
    return YES;
}

+ (BOOL)replaceStore:(NSURL*)old withStore:(NSURL*)new
{
    BOOL success = NO;
    NSError *error = nil;
    if ([[NSFileManager defaultManager] removeItemAtURL:old error:&error]) {
        
        error = nil;
        if ([[NSFileManager defaultManager] moveItemAtURL:new toURL:old error:&error]) {
            success = YES;
        } else {
            PCFPushCriticalLog(@"ERROR: Unable to replace the old store with the new store: %@", error);
        }
    } else {
        PCFPushCriticalLog(@"ERROR: Unable to remove old store %@: %@", old, error);
    }
    return success;
}

+ (NSUInteger)numberOfMigrationsExecuted
{
    return _numberOfMigrations;
}


@end