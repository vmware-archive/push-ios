//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "NSObject+PCFJSONizable.h"
#import "PCFMapping.h"
#import "PCFPushErrorUtil.h"
#import "PCFPushDebug.h"
#import "PCFPushErrors.h"
#import "PCFPushRegistrationData.h"

@implementation NSObject (PCFJSONizable)

- (id)pcf_toFoundationType
{
    id foundationType;
    if ([self isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *convertedDictionary = [NSMutableDictionary dictionaryWithCapacity:[(NSDictionary *)self count]];
        [(NSDictionary *)self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [convertedDictionary setValue:[obj pcf_toFoundationType] forKeyPath:key];
        }];
        foundationType = convertedDictionary;
        
    } else if ([self conformsToProtocol:@protocol(PCFMapping)]) {
        NSDictionary *mapping = [self.class localToRemoteMapping];
        foundationType = [NSMutableDictionary dictionaryWithCapacity:mapping.allKeys.count];
        [mapping enumerateKeysAndObjectsUsingBlock:^(NSString *propertyName, NSString *remoteKey, BOOL *stop) {
            id value = [self valueForKey:propertyName];
            if (value) {
                NSArray *components = [remoteKey componentsSeparatedByString:@"."];
                if (components.count == 1) {
                    // Handle simple items
                    foundationType[remoteKey] = value;
                } else if (components.count > 1) {
                    // Handle nested items
                    NSUInteger componentIndex = 0;
                    id currentItem = foundationType;
                    while (componentIndex < components.count) {
                        id componentName = components[componentIndex];
                        if (componentIndex == components.count - 1) {
                            currentItem[componentName] = value;
                        } else {
                            if (!currentItem[componentName]) {
                                currentItem[componentName] = [NSMutableDictionary dictionary];
                            }
                            currentItem = currentItem[componentName];
                        }
                        componentIndex += 1;
                    }
                }
            }
        }];
        
    } else if ([self isKindOfClass:[NSArray class]]) {
        NSMutableArray *convertedArray = [[NSMutableArray alloc] initWithCapacity:[(NSArray *)self count]];
        [(NSArray *)self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            id newType = [obj pcf_toFoundationType];
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

- (NSData *)pcf_toJSONData:(NSError **)error
{
    NSData *JSONData = [NSJSONSerialization dataWithJSONObject:[self pcf_toFoundationType] options:0 error:error];
    if (!JSONData) {
        PCFPushCriticalLog(@"Error upon serializing object to JSON: %@", error);
        return nil;
        
    } else {
        return JSONData;
    }
}

+ (instancetype)pcf_fromDictionary:(NSDictionary *)dict
{
    id result;
    
    if ([self conformsToProtocol:@protocol(PCFMapping)]) {
        NSDictionary *mapping = [self.class localToRemoteMapping];
        result = [[self alloc] init];
        [mapping enumerateKeysAndObjectsUsingBlock:^(NSString *propertyName, NSString *remoteKey, BOOL *stop) {
            id value = [dict valueForKeyPath:remoteKey];
            if (value) {
                [result setValue:value forKey:propertyName];
            }
        }];
    }
    
    return result;
}

+ (instancetype)pcf_fromJSONData:(NSData *)JSONData error:(NSError **)error
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
    
    return [self pcf_fromDictionary:dict];
}

@end
