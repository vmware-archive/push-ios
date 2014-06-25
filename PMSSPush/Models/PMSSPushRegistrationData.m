//
//  PMSSPushBackEndRegistrationData.m
//  PMSSPushSDK
//
//  Created by DX123-XL on 3/7/2014.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import <objc/runtime.h>

#import "PMSSPushRegistrationData.h"
#import "PMSSPushErrors.h"
#import "PMSSPushErrorUtil.h"
#import "PMSSPushDebug.h"

const struct RegistrationAttributes {
    PMSS_STRUCT_STRING *variantUUID;
    PMSS_STRUCT_STRING *deviceAlias;
    PMSS_STRUCT_STRING *deviceManufacturer;
    PMSS_STRUCT_STRING *deviceModel;
    PMSS_STRUCT_STRING *deviceOS;
    PMSS_STRUCT_STRING *deviceOSVersion;
    PMSS_STRUCT_STRING *registrationToken;
} RegistrationAttributes;

const struct RegistrationAttributes RegistrationAttributes = {
    .variantUUID         = @"variant_uuid",
    .deviceAlias         = @"device_alias",
    .deviceManufacturer  = @"device_manufacturer",
    .deviceModel         = @"device_model",
    .deviceOS            = @"os",
    .deviceOSVersion     = @"os_version",
    .registrationToken   = @"registration_token",
};

@implementation PMSSPushRegistrationData

+ (NSDictionary *)localToRemoteMapping
{
    static NSDictionary *localToRemoteMapping;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        localToRemoteMapping = @{
                                 PMSS_STR_PROP(variantUUID) : RegistrationAttributes.variantUUID,
                                 PMSS_STR_PROP(deviceAlias) : RegistrationAttributes.deviceAlias,
                                 PMSS_STR_PROP(deviceManufacturer) : RegistrationAttributes.deviceManufacturer,
                                 PMSS_STR_PROP(deviceModel) : RegistrationAttributes.deviceModel,
                                 PMSS_STR_PROP(os) : RegistrationAttributes.deviceOS,
                                 PMSS_STR_PROP(osVersion) : RegistrationAttributes.deviceOSVersion,
                                 PMSS_STR_PROP(registrationToken) : RegistrationAttributes.registrationToken,
                                 };
    });
    return localToRemoteMapping;
}

@end
