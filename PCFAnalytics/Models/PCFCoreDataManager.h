//
//  PCFPushDBManager.h
//  
//
//  Created by DX123-XL on 2014-03-27.
//
//

#import <Foundation/Foundation.h>

@interface PCFCoreDataManager : NSObject

+ (instancetype)shared;

+ (void)setSharedManager:(PCFCoreDataManager *)manager;

- (void)flushDatabase;

- (NSManagedObjectContext *)managedObjectContext;

- (NSArray *)managedObjectsWithEntityName:(NSString *)entityName;

- (void)deleteManagedObjects:(NSArray *)managedObjects;

@end
