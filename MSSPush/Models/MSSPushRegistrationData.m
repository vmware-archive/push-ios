//
//  MSSPushBackEndRegistrationData.m
//  MSSPush
//
//  Created by DX123-XL on 3/7/2014.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import <objc/runtime.h>

#import "MSSPushRegistrationData.h"
#import "MSSPushErrors.h"
#import "MSSPushErrorUtil.h"
#import "MSSPushDebug.h"

const struct RegistrationAttributes {
    MSS_STRUCT_STRING *variantUUID;
    MSS_STRUCT_STRING *deviceAlias;
    MSS_STRUCT_STRING *deviceManufacturer;
    MSS_STRUCT_STRING *deviceModel;
    MSS_STRUCT_STRING *deviceOS;
    MSS_STRUCT_STRING *deviceOSVersion;
    MSS_STRUCT_STRING *registrationToken;
    MSS_STRUCT_STRING *tags;
} RegistrationAttributes;

const struct RegistrationAttributes RegistrationAttributes = {
    .variantUUID         = @"variant_uuid",
    .deviceAlias         = @"device_alias",
    .deviceManufacturer  = @"device_manufacturer",
    .deviceModel         = @"device_model",
    .deviceOS            = @"os",
    .deviceOSVersion     = @"os_version",
    .registrationToken   = @"registration_token",
    .tags                = @"tags",
};

@implementation MSSPushRegistrationData

+ (NSDictionary *)localToRemoteMapping
{
    static NSDictionary *localToRemoteMapping;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        localToRemoteMapping = @{
                                 MSS_STR_PROP(variantUUID) : RegistrationAttributes.variantUUID,
                                 MSS_STR_PROP(deviceAlias) : RegistrationAttributes.deviceAlias,
                                 MSS_STR_PROP(deviceManufacturer) : RegistrationAttributes.deviceManufacturer,
                                 MSS_STR_PROP(deviceModel) : RegistrationAttributes.deviceModel,
                                 MSS_STR_PROP(os) : RegistrationAttributes.deviceOS,
                                 MSS_STR_PROP(osVersion) : RegistrationAttributes.deviceOSVersion,
                                 MSS_STR_PROP(registrationToken) : RegistrationAttributes.registrationToken,
                                 MSS_STR_PROP(tags) : RegistrationAttributes.tags,
                                 };
    });
    return localToRemoteMapping;
}

@end
