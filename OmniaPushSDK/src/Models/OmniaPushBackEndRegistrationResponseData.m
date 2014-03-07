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
    if (self.releaseUUID) {
        dict[kReleaseUUID] = self.releaseUUID;
    }
    if (self.deviceUUID) {
        dict[kDeviceUUID] = self.deviceUUID;
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
    OmniaPushBackEndRegistrationResponseData *result = [[OmniaPushBackEndRegistrationResponseData alloc] init];
    result.os = dict[kDeviceOS];
    result.osVersion = dict[kDeviceOSVersion];
    result.deviceUUID = dict[kDeviceUUID];
    result.deviceAlias = dict[kDeviceAlias];
    result.deviceManufacturer = dict[kDeviceManufacturer];
    result.deviceModel = dict[kDeviceModel];
    result.releaseUUID = dict[kReleaseUUID];
    result.registrationToken = dict[kRegistrationToken];
    return result;
}

+ (instancetype)fromJSONData:(NSData *)JSONData error:(NSError **)error
{
    *error = nil;
    
    if (!JSONData || JSONData.length <= 0) {
        *error = [OmniaPushErrorUtil errorWithCode:OmniaPushBackEndRegistrationResponseDataUnparseable localizedDescription:@"response data is empty"];
        return nil;
    }
    
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:JSONData options:0 error:error];
    
    if (*error != nil) {
        return nil;
    }
    
    return [OmniaPushBackEndRegistrationResponseData fromDictionary:dict];
}

@end
