//
//  CFPushBackEndRegistrationData.m
//  CFPushSDK
//
//  Created by DX123-XL on 3/7/2014.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import <objc/runtime.h>

#import "CFPushRegistrationData.h"
#import "CFPushErrors.h"
#import "CFPushErrorUtil.h"
#import "CFPushDebug.h"

NSString *const kReleaseUUID         = @"release_uuid";
NSString *const kDeviceAlias         = @"device_alias";
NSString *const kDeviceManufacturer  = @"device_manufacturer";
NSString *const kDeviceModel         = @"device_model";
NSString *const kDeviceOS            = @"os";
NSString *const kDeviceOSVersion     = @"os_version";
NSString *const kRegistrationToken   = @"registration_token";

@implementation CFPushRegistrationData

+ (NSDictionary *)localToRemoteMapping
{
    static NSDictionary *localToRemoteMapping;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        localToRemoteMapping = @{
                                 CF_STR_PROP(releaseUUID) : kReleaseUUID,
                                 CF_STR_PROP(deviceAlias) : kDeviceAlias,
                                 CF_STR_PROP(deviceManufacturer) : kDeviceManufacturer,
                                 CF_STR_PROP(deviceModel) : kDeviceModel,
                                 CF_STR_PROP(os) : kDeviceOS,
                                 CF_STR_PROP(osVersion) : kDeviceOSVersion,
                                 CF_STR_PROP(registrationToken) : kRegistrationToken,
                                 };
    });
    return localToRemoteMapping;
}

- (NSDictionary *)toDictionary
{
    NSDictionary *mapping = [self.class localToRemoteMapping];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:mapping.allKeys.count];
    
    [mapping enumerateKeysAndObjectsUsingBlock:^(NSString *propertyName, NSString *remoteKey, BOOL *stop) {
        id value = [self valueForKey:propertyName];
        if (value) {
            [dict setObject:value forKey:remoteKey];
        }
    }];
    
    return dict;
}

- (NSData *)toJSONData:(NSError **)error
{
    NSData *JSONData = [NSJSONSerialization dataWithJSONObject:[self toDictionary] options:0 error:error];
    if (!JSONData) {
        CFPushCriticalLog(@"Error upon serializing object to JSON: %@", error);
        return nil;
        
    } else {
        return JSONData;
    }
}

+ (instancetype)fromDictionary:(NSDictionary *)dict
{
    NSDictionary *mapping = [self localToRemoteMapping];
    id result = [[self alloc] init];
    
    [mapping enumerateKeysAndObjectsUsingBlock:^(NSString *propertyName, NSString *remoteKey, BOOL *stop) {
        if (dict[remoteKey]) {
            [result setValue:dict[remoteKey] forKey:propertyName];
        }
    }];
    
    return result;
}

+ (instancetype)fromJSONData:(NSData *)JSONData error:(NSError **)error
{
    if (!JSONData || JSONData.length <= 0) {
        if (error) {
            *error = [CFPushErrorUtil errorWithCode:CFPushBackEndRegistrationDataUnparseable localizedDescription:@"request data is empty"];
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
