//
//  NSObject+PCFJsonizable.m
//  
//
//  Created by DX123-XL on 2014-03-31.
//
//

#import "NSObject+PCFJsonizable.h"
#import "PCFMapping.h"
#import "PCFPushErrorUtil.h"
#import "PCFPushDebug.h"
#import "PCFPushErrors.h"

@implementation NSObject (PCFJSONizable)

- (id)toFoundationType
{
    id foundationType;
    if ([self isKindOfClass:[NSDictionary class]]) {
        foundationType = self;
        
    } else if ([self conformsToProtocol:@protocol(PCFMapping)]) {
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
            id newType = [obj toFoundationType];
            if (newType) {
                [convertedArray addObject:newType];
            }
        }];
        foundationType = [NSArray arrayWithArray:convertedArray];
    }
    
    return foundationType;
}

- (NSData *)toJSONData:(NSError **)error
{
    NSData *JSONData = [NSJSONSerialization dataWithJSONObject:[self toFoundationType] options:0 error:error];
    if (!JSONData) {
        PCFPushCriticalLog(@"Error upon serializing object to JSON: %@", error);
        return nil;
        
    } else {
        return JSONData;
    }
}

+ (instancetype)fromDictionary:(NSDictionary *)dict
{
    id result;
    
    if ([self conformsToProtocol:@protocol(PCFMapping)]) {
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

+ (instancetype)fromJSONData:(NSData *)JSONData error:(NSError **)error
{
    if (!JSONData || JSONData.length <= 0) {
        if (error) {
            *error = [PCFPushErrorUtil errorWithCode:PCFPushBackEndRegistrationDataUnparseable localizedDescription:@"request data is empty"];
        }
        return nil;
    }
    
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:JSONData options:0 error:error];
    
    if (*error) {
        return nil;
    }
    
    return [self fromDictionary:dict];
}

@end
