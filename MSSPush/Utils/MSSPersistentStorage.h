//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MSSPersistentStorage : NSObject

+ (void)persistValue:(id)value forKey:(id)key;
+ (id)persistedValueForKey:(id)key;
+ (void)removeObjectForKey:(id)key;

+ (void)setServerDeviceID:(NSString *)backEndDeviceID;
+ (NSString *)serverDeviceID;

+ (void)reset;

@end
