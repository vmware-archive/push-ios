//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PCFMapping.h"

struct PCFPushRegistrationAttributes {
    PCF_STRUCT_STRING *variantUUID;
    PCF_STRUCT_STRING *deviceAlias;
    PCF_STRUCT_STRING *deviceManufacturer;
    PCF_STRUCT_STRING *deviceModel;
    PCF_STRUCT_STRING *deviceOS;
    PCF_STRUCT_STRING *deviceOSVersion;
    PCF_STRUCT_STRING *registrationToken;
    PCF_STRUCT_STRING *tags;
};

extern const struct PCFPushRegistrationAttributes PCFPushRegistrationAttributes;

@interface PCFPushRegistrationData : NSObject <PCFMapping>

@property NSString *variantUUID;
@property NSString *deviceAlias;
@property NSString *deviceManufacturer;
@property NSString *deviceModel;
@property NSString *os;
@property NSString *osVersion;
@property NSString *registrationToken;

+ (NSDictionary *)localToRemoteMapping;

@end
