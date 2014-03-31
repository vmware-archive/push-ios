//
//  PCFPushDBManager.h
//  
//
//  Created by DX123-XL on 2014-03-27.
//
//

#import <Foundation/Foundation.h>

@class PCFAnalyticEvent;

@interface PCFPushCoreDataManager : NSObject

+ (instancetype)shared;

- (NSManagedObjectContext *)managedObjectContext;

@end
