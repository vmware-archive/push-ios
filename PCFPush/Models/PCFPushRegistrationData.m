//
//  PCFPushBackEndRegistrationData.m
//  PCFPushSDK
//
//  Created by DX123-XL on 3/7/2014.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import <objc/runtime.h>

#import "PCFPushRegistrationData.h"
#import "PCFPushErrors.h"
#import "PCFPushErrorUtil.h"
#import "PCFPushDebug.h"

const struct RegistrationAttributes {
    PCF_STRUCT_STRING *variantUUID;
    PCF_STRUCT_STRING *deviceAlias;
    PCF_STRUCT_STRING *deviceManufacturer;
    PCF_STRUCT_STRING *deviceModel;
    PCF_STRUCT_STRING *deviceOS;
    PCF_STRUCT_STRING *deviceOSVersion;
    PCF_STRUCT_STRING *registrationToken;
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

@implementation PCFPushRegistrationData

+ (NSDictionary *)localToRemoteMapping
{
    static NSDictionary *localToRemoteMapping;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        localToRemoteMapping = @{
                                 PCF_STR_PROP(variantUUID) : RegistrationAttributes.variantUUID,
                                 PCF_STR_PROP(deviceAlias) : RegistrationAttributes.deviceAlias,
                                 PCF_STR_PROP(deviceManufacturer) : RegistrationAttributes.deviceManufacturer,
                                 PCF_STR_PROP(deviceModel) : RegistrationAttributes.deviceModel,
                                 PCF_STR_PROP(os) : RegistrationAttributes.deviceOS,
                                 PCF_STR_PROP(osVersion) : RegistrationAttributes.deviceOSVersion,
                                 PCF_STR_PROP(registrationToken) : RegistrationAttributes.registrationToken,
                                 };
    });
    return localToRemoteMapping;
}

@end
