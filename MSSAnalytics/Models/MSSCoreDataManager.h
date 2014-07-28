//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MSSCoreDataManager : NSObject

+ (instancetype)shared;

+ (void)setSharedManager:(MSSCoreDataManager *)manager;

- (void)flushDatabase;

- (NSManagedObjectContext *)managedObjectContext;

- (NSArray *)managedObjectsWithEntityName:(NSString *)entityName;

- (void)deleteManagedObjects:(NSArray *)managedObjects;

@end
