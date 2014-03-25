//
//  OmniaPushBackEndRegistrationData.m
//  OmniaPushSDK
//
//  Created by DX123-XL on 3/7/2014.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import <objc/runtime.h>

#import "OmniaPushBackEndRegistrationData.h"
#import "OmniaPushErrors.h"
#import "OmniaPushErrorUtil.h"
#import "OmniaPushDebug.h"

NSString *const kReleaseUUID         = @"release_uuid";
NSString *const kDeviceAlias         = @"device_alias";
NSString *const kDeviceManufacturer  = @"device_manufacturer";
NSString *const kDeviceModel         = @"device_model";
NSString *const kDeviceOS            = @"os";
NSString *const kDeviceOSVersion     = @"os_version";
NSString *const kRegistrationToken   = @"registration_token";

@implementation OmniaPushBackEndRegistrationData

+ (NSDictionary *)localToRemoteMapping
{
    static NSDictionary *localToRemoteMapping;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        localToRemoteMapping = @{
                                 OMNIA_STR_PROP(releaseUUID) : kReleaseUUID,
                                 OMNIA_STR_PROP(deviceAlias) : kDeviceAlias,
                                 OMNIA_STR_PROP(deviceManufacturer) : kDeviceManufacturer,
                                 OMNIA_STR_PROP(deviceModel) : kDeviceModel,
                                 OMNIA_STR_PROP(os) : kDeviceOS,
                                 OMNIA_STR_PROP(osVersion) : kDeviceOSVersion,
                                 OMNIA_STR_PROP(registrationToken) : kRegistrationToken,
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
        OmniaPushCriticalLog(@"Error upon serializing object to JSON: %@", error);
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
            *error = [OmniaPushErrorUtil errorWithCode:OmniaPushBackEndRegistrationDataUnparseable localizedDescription:@"request data is empty"];
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
