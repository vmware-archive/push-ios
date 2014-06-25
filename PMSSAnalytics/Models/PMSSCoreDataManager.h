//
//  PMSSCoreDataManager.h
//  
//
//  Created by DX123-XL on 2014-03-27.
//
//

#import <Foundation/Foundation.h>

@interface PMSSCoreDataManager : NSObject

+ (instancetype)shared;

+ (void)setSharedManager:(PMSSCoreDataManager *)manager;

- (void)flushDatabase;

- (NSManagedObjectContext *)managedObjectContext;

- (NSArray *)managedObjectsWithEntityName:(NSString *)entityName;

- (void)deleteManagedObjects:(NSArray *)managedObjects;

@end
