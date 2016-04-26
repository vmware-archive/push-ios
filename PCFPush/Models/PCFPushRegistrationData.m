//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "PCFPushRegistrationData.h"

const struct PCFPushRegistrationAttributes PCFPushRegistrationAttributes = {
    .variantUUID         = @"variant_uuid",
    .customUserId        = @"custom_user_id",
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
                                 PCF_STR_PROP(variantUUID) : PCFPushRegistrationAttributes.variantUUID,
                                 PCF_STR_PROP(customUserId) : PCFPushRegistrationAttributes.customUserId,
                                 PCF_STR_PROP(deviceAlias) : PCFPushRegistrationAttributes.deviceAlias,
                                 PCF_STR_PROP(deviceManufacturer) : PCFPushRegistrationAttributes.deviceManufacturer,
                                 PCF_STR_PROP(deviceModel) : PCFPushRegistrationAttributes.deviceModel,
                                 PCF_STR_PROP(os) : PCFPushRegistrationAttributes.deviceOS,
                                 PCF_STR_PROP(osVersion) : PCFPushRegistrationAttributes.deviceOSVersion,
                                 PCF_STR_PROP(registrationToken) : PCFPushRegistrationAttributes.registrationToken,
                                 };
    });
    return localToRemoteMapping;
}

@end
