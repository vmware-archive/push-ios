//
//  OmniaPushBackEndRegistrationResponseData.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-21.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "OmniaPushBackEndRegistrationResponseData.h"
#import "OmniaPushBackEndRegistrationRequestData.h"
#import "OmniaPushErrors.h"
#import "OmniaPushErrorUtil.h"
#import "OmniaPushDebug.h"

@implementation OmniaPushBackEndRegistrationResponseData

- (NSDictionary*) toDictionary
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if (self.releaseUuid) {
        dict[kReleaseUUID] = self.releaseUuid;
    }
    if (self.deviceUuid) {
        dict[kDeviceUUID] = self.deviceUuid;
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
    OmniaPushBackEndRegistrationResponseData *result = [[OmniaPushBackEndRegistrationResponseData alloc] init];
    result.os = dict[kDeviceOS];
    result.osVersion = dict[kDeviceOSVersion];
    result.deviceUuid = dict[kDeviceUUID];
    result.deviceAlias = dict[kDeviceAlias];
    result.deviceManufacturer = dict[kDeviceManufacturer];
    result.deviceModel = dict[kDeviceModel];
    result.releaseUuid = dict[kReleaseUUID];
    result.registrationToken = dict[kRegistrationToken];
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
