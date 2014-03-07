//
//  OmniaPushBackEndRegistrationRequestData.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-21.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import <objc/runtime.h>

#import "OmniaPushBackEndRegistrationRequestData.h"
#import "OmniaPushErrors.h"
#import "OmniaPushErrorUtil.h"
#import "OmniaPushDebug.h"

#ifndef STR_PROP
#define STR_PROP( prop ) NSStringFromSelector(@selector(prop))
#endif

NSString *const kReleaseUUID         = @"release_uuid";
NSString *const kDeviceUUID          = @"device_uuid";
NSString *const kReleaseSecret       = @"secret";
NSString *const kDeviceAlias         = @"device_alias";
NSString *const kDeviceManufacturer  = @"device_manufacturer";
NSString *const kDeviceModel         = @"device_model";
NSString *const kDeviceOS            = @"os";
NSString *const kDeviceOSVersion     = @"os_version";
NSString *const kRegistrationToken   = @"registration_token";

@implementation OmniaPushBackEndRegistrationRequestData

+ (NSDictionary *)localToRemoteMapping
{
    static NSDictionary *localToRemoteMapping;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        localToRemoteMapping = @{
                                 STR_PROP(releaseUUID) : kReleaseUUID,
                                 STR_PROP(deviceAlias) : kDeviceAlias,
                                 STR_PROP(secret) : kReleaseSecret,
                                 STR_PROP(deviceManufacturer) : kDeviceManufacturer,
                                 STR_PROP(deviceModel) : kDeviceModel,
                                 STR_PROP(os) : kDeviceOS,
                                 STR_PROP(osVersion) : kDeviceOSVersion,
                                 STR_PROP(registrationToken) : kRegistrationToken,
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

- (NSData *)toJSONData
{
    NSError *error = nil;
    NSData *JSONData = [NSJSONSerialization dataWithJSONObject:[self toDictionary] options:0 error:&error];
    if (error) {
        // TODO - should return error?
        OmniaPushCriticalLog(@"Error upon serializing object to JSON: %@", error);
        return nil;
    } else {
        return JSONData;
    }
}

+ (instancetype)fromDictionary:(NSDictionary *)dict
{
    NSDictionary *mapping = [self.class localToRemoteMapping];
    OmniaPushBackEndRegistrationRequestData *result = [[OmniaPushBackEndRegistrationRequestData alloc] init];
    
    [mapping enumerateKeysAndObjectsUsingBlock:^(NSString *propertyName, NSString *remoteKey, BOOL *stop) {
        if (dict[remoteKey]) {
            [result setValue:dict[remoteKey] forKey:propertyName];
        }
    }];

    return result;
}

+ (instancetype)fromJSONData:(NSData *)JSONData error:(NSError**)error
{
    *error = nil;
    
    if (JSONData == nil || JSONData.length <= 0) {
        *error = [OmniaPushErrorUtil errorWithCode:OmniaPushBackEndRegistrationRequestDataUnparseable localizedDescription:@"request data is empty"];
        return nil;
    }
    
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:JSONData options:0 error:error];
    
    if (*error != nil) {
        return nil;
    }
    
    return [OmniaPushBackEndRegistrationRequestData fromDictionary:dict];
}

@end
