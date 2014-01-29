//
//  OmniaPushBackEndRegistrationResponseData.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-21.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import "OmniaPushBackEndRegistrationResponseData.h"
#import "OmniaPushErrors.h"
#import "OmniaPushErrorUtil.h"
#import "OmniaPushDebug.h"

@implementation OmniaPushBackEndRegistrationResponseData

- (NSDictionary*) toDictionary
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if (self.releaseUuid) dict[@"release_uuid"] = self.releaseUuid;
    if (self.deviceUuid) dict[@"device_uuid"] = self.deviceUuid;
    if (self.deviceAlias) dict[@"device_alias"] = self.deviceAlias;
    if (self.deviceManufacturer) dict[@"device_manufacturer"] = self.deviceManufacturer;
    if (self.deviceModel) dict[@"device_model"] = self.deviceModel;
    if (self.os) dict[@"os"] = self.os;
    if (self.osVersion) dict[@"os_version"] = self.osVersion;
    if (self.registrationToken) dict[@"registration_token"] = self.registrationToken;
    return dict;
}

- (NSData*) toJsonData
{
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[self toDictionary] options:0 error:&error];
    if (error) {
        // TODO - should return error?
        OmniaPushCriticalLog(@"Error upon serializing object to JSON: %@", error);
        return nil;
    } else {
        return jsonData;
    }
}

+ (instancetype) fromDictionary:(NSDictionary*)dict
{
    OmniaPushBackEndRegistrationResponseData *result = [[OmniaPushBackEndRegistrationResponseData alloc] init];
    result.os = dict[@"os"];
    result.osVersion = dict[@"os_version"];
    result.deviceUuid = dict[@"device_uuid"];
    result.deviceAlias = dict[@"device_alias"];
    result.deviceManufacturer = dict[@"device_manufacturer"];
    result.deviceModel = dict[@"device_model"];
    result.releaseUuid = dict[@"release_uuid"];
    result.registrationToken = dict[@"registration_token"];
    return result;
}

+ (instancetype) fromJsonData:(NSData*)jsonData error:(NSError**)error
{
    *error = nil;
    
    if (jsonData == nil || jsonData.length <= 0) {
        *error = [OmniaPushErrorUtil errorWithCode:OmniaPushBackEndRegistrationResponseDataUnparseable localizedDescription:@"response data is empty"];
        return nil;
    }
    
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:error];
    
    if (*error != nil) {
        return nil;
    }
    
    return [OmniaPushBackEndRegistrationResponseData fromDictionary:dict];
}

@end
