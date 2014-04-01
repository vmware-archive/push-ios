//
//  PCFPushDBManager.h
//  
//
//  Created by DX123-XL on 2014-03-27.
//
//

#import <Foundation/Foundation.h>

@interface PCFPushCoreDataManager : NSObject

+ (instancetype)shared;

- (NSManagedObjectContext *)managedObjectContext;

- (void)deleteManagedObjects:(NSArray *)managedObjects;

@end
