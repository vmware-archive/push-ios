//
//  MSSPersistentStorage.h
//  
//
//  Created by DX123-XL on 2014-04-25.
//
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
