//
//  MSSCoreDataManager.h
//  
//
//  Created by DX123-XL on 2014-03-27.
//
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
