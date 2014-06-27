//
//  NSObject+MSSJsonizable.m
//  
//
//  Created by DX123-XL on 2014-03-31.
//
//

#import "NSObject+MSSJsonizable.h"
#import "MSSMapping.h"
#import "MSSPushErrorUtil.h"
#import "MSSPushDebug.h"
#import "MSSPushErrors.h"

@implementation NSObject (MSSJSONizable)

- (id)mss_toFoundationType
{
    id foundationType;
    if ([self isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *convertedDictionary = [NSMutableDictionary dictionaryWithCapacity:[(NSDictionary *)self count]];
        [(NSDictionary *)self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [convertedDictionary setValue:[obj mss_toFoundationType] forKeyPath:key];
        }];
        foundationType = convertedDictionary;
        
    } else if ([self conformsToProtocol:@protocol(MSSMapping)]) {
        NSDictionary *mapping = [self.class localToRemoteMapping];
        foundationType = [NSMutableDictionary dictionaryWithCapacity:mapping.allKeys.count];
        [mapping enumerateKeysAndObjectsUsingBlock:^(NSString *propertyName, NSString *remoteKey, BOOL *stop) {
            id value = [self valueForKey:propertyName];
            if (value) {
                [foundationType setObject:value forKey:remoteKey];
            }
        }];
        
    } else if ([self isKindOfClass:[NSArray class]]) {
        NSMutableArray *convertedArray = [[NSMutableArray alloc] initWithCapacity:[(NSArray *)self count]];
        [(NSArray *)self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            id newType = [obj mss_toFoundationType];
            if (newType) {
                [convertedArray addObject:newType];
            }
        }];
        foundationType = [NSArray arrayWithArray:convertedArray];
        
    } else {
        foundationType = self;
    }
    
    return foundationType;
}

- (NSData *)mss_toJSONData:(NSError **)error
{
    NSData *JSONData = [NSJSONSerialization dataWithJSONObject:[self mss_toFoundationType] options:0 error:error];
    if (!JSONData) {
        MSSPushCriticalLog(@"Error upon serializing object to JSON: %@", error);
        return nil;
        
    } else {
        return JSONData;
    }
}

+ (instancetype)mss_fromDictionary:(NSDictionary *)dict
{
    id result;
    
    if ([self conformsToProtocol:@protocol(MSSMapping)]) {
        NSDictionary *mapping = [self.class localToRemoteMapping];
        result = [[self alloc] init];
        [mapping enumerateKeysAndObjectsUsingBlock:^(NSString *propertyName, NSString *remoteKey, BOOL *stop) {
            if (dict[remoteKey]) {
                [result setValue:dict[remoteKey] forKey:propertyName];
            }
        }];
    }
    
    return result;
}

+ (instancetype)mss_fromJSONData:(NSData *)JSONData error:(NSError **)error
{
    if (!JSONData || JSONData.length <= 0) {
        if (error) {
            *error = [MSSPushErrorUtil errorWithCode:MSSPushBackEndRegistrationDataUnparseable localizedDescription:@"request data is empty"];
        }
        return nil;
    }
    
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:JSONData options:0 error:error];
    
    if (*error) {
        return nil;
    }
    
    return [self mss_fromDictionary:dict];
}

@end
