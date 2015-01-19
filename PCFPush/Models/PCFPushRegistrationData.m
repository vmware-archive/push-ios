//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "PCFPushRegistrationData.h"

const struct RegistrationAttributes RegistrationAttributes = {
    .variantUUID         = @"variant_uuid",
    .deviceAlias         = @"device_alias",
    .deviceManufacturer  = @"device_manufacturer",
    .deviceModel         = @"device_model",
    .deviceOS            = @"os",
    .deviceOSVersion     = @"os_version",
    .registrationToken   = @"registration_token",
    .tags                = @"tags"
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
