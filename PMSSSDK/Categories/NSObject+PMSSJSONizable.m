//
//  NSObject+PMSSJsonizable.m
//  
//
//  Created by DX123-XL on 2014-03-31.
//
//

#import "NSObject+PMSSJsonizable.h"
#import "PMSSMapping.h"
#import "PMSSPushErrorUtil.h"
#import "PMSSPushDebug.h"
#import "PMSSPushErrors.h"

@implementation NSObject (PMSSJSONizable)

- (id)pmss_toFoundationType
{
    id foundationType;
    if ([self isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *convertedDictionary = [NSMutableDictionary dictionaryWithCapacity:[(NSDictionary *)self count]];
        [(NSDictionary *)self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [convertedDictionary setValue:[obj pmss_toFoundationType] forKeyPath:key];
        }];
        foundationType = convertedDictionary;
        
    } else if ([self conformsToProtocol:@protocol(PMSSMapping)]) {
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
            id newType = [obj pmss_toFoundationType];
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

- (NSData *)pmss_toJSONData:(NSError **)error
{
    NSData *JSONData = [NSJSONSerialization dataWithJSONObject:[self pmss_toFoundationType] options:0 error:error];
    if (!JSONData) {
        PMSSPushCriticalLog(@"Error upon serializing object to JSON: %@", error);
        return nil;
        
    } else {
        return JSONData;
    }
}

+ (instancetype)pmss_fromDictionary:(NSDictionary *)dict
{
    id result;
    
    if ([self conformsToProtocol:@protocol(PMSSMapping)]) {
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

+ (instancetype)pmss_fromJSONData:(NSData *)JSONData error:(NSError **)error
{
    if (!JSONData || JSONData.length <= 0) {
        if (error) {
            *error = [PMSSPushErrorUtil errorWithCode:PMSSPushBackEndRegistrationDataUnparseable localizedDescription:@"request data is empty"];
        }
        return nil;
    }
    
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:JSONData options:0 error:error];
    
    if (*error) {
        return nil;
    }
    
    return [self pmss_fromDictionary:dict];
}

@end
