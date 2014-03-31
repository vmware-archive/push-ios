//
//  PCFPushDBManager.m
//  
//
//  Created by DX123-XL on 2014-03-27.
//
//

#import <CoreData/CoreData.h>

#import "PCFPushCoreDataManager.h"
#import "PCFPushDebug.h"
#import "PCFAnalyticEvent.h"

static NSString *const kDatabaseDirectoryName = @"PCFPushAnalyticsDB";
static NSString *const kDatabaseFileName = @"PCFPushAnalyticsDB.sqlite";

@interface PCFPushCoreDataManager ()

@property (nonatomic) NSURL *databaseURL;
@property (nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) NSManagedObjectModel *managedObjectModel;
@property (nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end

static PCFPushCoreDataManager *_sharedCoreDataManager;
static dispatch_once_t onceToken;

@implementation PCFPushCoreDataManager

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

+ (void)setSharedManager:(PCFPushCoreDataManager *)manager
{
    onceToken = 0;
    _sharedCoreDataManager = manager;
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
            _managedObjectContext = [[NSManagedObjectContext alloc] init];
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
    if (!_managedObjectModel) {
        return _managedObjectModel;
    }
    _managedObjectModel = [[NSManagedObjectModel alloc] init];
    NSString *entityName = NSStringFromClass([PCFAnalyticEvent class]);
    NSEntityDescription *analyticEventEntity = [[NSEntityDescription alloc] init];
    [analyticEventEntity setName:entityName];
    [analyticEventEntity setManagedObjectClassName:entityName];
    [_managedObjectModel setEntities:@[analyticEventEntity]];
    
    NSArray *analyticEventProperties = @[
                                         [self attributeDescriptionWithName:EventAttributes.eventID type:NSStringAttributeType optional:true],
                                         [self attributeDescriptionWithName:EventAttributes.eventType type:NSStringAttributeType optional:true],
                                         [self attributeDescriptionWithName:EventAttributes.eventTime type:NSDateAttributeType optional:true],
                                         ];
    
    [analyticEventEntity setProperties:analyticEventProperties];
    
    return _managedObjectModel;
}

- (NSAttributeDescription *)attributeDescriptionWithName:(NSString *)name
                                                type:(NSAttributeType)attributeType
                                             optional:(BOOL)isOptional
{
    NSAttributeDescription *attribute = [[NSAttributeDescription alloc] init];
    [attribute setName:name];
    [attribute setAttributeType:attributeType];
    [attribute setOptional:isOptional];
    
    return attribute;
}


- (NSURL *)databaseURL
{
    if (!_databaseURL) {
        return _databaseURL;
    }
    
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
    _databaseURL = [directoryURL URLByAppendingPathComponent:kDatabaseFileName];
    return _databaseURL;
}

@end
