//
//  OmniaPushBackEndRegistrationRequestData.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-21.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import "OmniaPushBackEndRegistrationRequestData.h"
#import "OmniaPushErrors.h"
#import "OmniaPushErrorUtil.h"
#import "OmniaPushDebug.h"

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

- (NSDictionary*) toDictionary
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if (self.releaseUuid) {
        dict[kReleaseUUID] = self.releaseUuid;
    }
    if (self.secret) {
        dict[kReleaseSecret] = self.secret;
    }
    if (self.deviceAlias) {
        dict[kDeviceAlias] = self.deviceAlias;
    }
    if (self.deviceManufacturer) {
        dict[kDeviceManufacturer] = self.deviceManufacturer;
    }
    if (self.deviceModel) {
        dict[kDeviceModel] = self.deviceModel;
    }
    if (self.os) {
        dict[kDeviceOS] = self.os;
    }
    if (self.osVersion) {
        dict[kDeviceOSVersion] = self.osVersion;
    }
    if (self.registrationToken) {
        dict[kRegistrationToken] = self.registrationToken;
    }
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
    OmniaPushBackEndRegistrationRequestData *result = [[OmniaPushBackEndRegistrationRequestData alloc] init];
    result.os = dict[kDeviceOS];
    result.osVersion = dict[kDeviceOSVersion];
    result.deviceAlias = dict[kDeviceAlias];
    result.deviceManufacturer = dict[kDeviceManufacturer];
    result.deviceModel = dict[kDeviceModel];
    result.releaseUuid = dict[kReleaseUUID];
    result.secret = dict[kReleaseSecret];
    result.registrationToken = dict[kRegistrationToken];
    return result;
}

+ (instancetype) fromJsonData:(NSData*)jsonData error:(NSError**)error
{
    *error = nil;
    
    if (jsonData == nil || jsonData.length <= 0) {
        *error = [OmniaPushErrorUtil errorWithCode:OmniaPushBackEndRegistrationRequestDataUnparseable localizedDescription:@"request data is empty"];
        return nil;
    }
    
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:error];
    
    if (*error != nil) {
        return nil;
    }
    
    return [OmniaPushBackEndRegistrationRequestData fromDictionary:dict];
}

@end
