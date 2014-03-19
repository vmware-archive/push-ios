//
//  OmniaPushBackEndRegistrationDataTest.h
//  OmniaPushSDK
//
//  Created by DX123-XL on 3/11/2014.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "OmniaPushBackEndRegistrationData.h"

OBJC_EXTERN NSString *const kReleaseUUID;
OBJC_EXTERN NSString *const kDeviceAlias;
OBJC_EXTERN NSString *const kDeviceManufacturer;
OBJC_EXTERN NSString *const kDeviceModel;
OBJC_EXTERN NSString *const kDeviceOS;
OBJC_EXTERN NSString *const kDeviceOSVersion;
OBJC_EXTERN NSString *const kRegistrationToken;

static NSString *const TEST_RELEASE_UUID        = @"123-456-789";
static NSString *const TEST_SECRET              = @"My cat's breath smells like cat food";
static NSString *const TEST_DEVICE_ALIAS        = @"l33t devices of badness";
static NSString *const TEST_DEVICE_MANUFACTURER = @"Commodore";
static NSString *const TEST_DEVICE_MODEL        = @"64C";
static NSString *const TEST_OS                  = @"BASIC";
static NSString *const TEST_OS_VERSION          = @"2.0";
static NSString *const TEST_REGISTRATION_TOKEN  = @"ABC-DEF-GHI";
static NSString *const TEST_DEVICE_UUID         = @"L337-L337-OH-YEAH";

@interface OmniaPushBackEndRegistrationData (TestingHeader)

@end