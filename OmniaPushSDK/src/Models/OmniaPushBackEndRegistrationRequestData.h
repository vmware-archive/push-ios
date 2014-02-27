//
//  OmniaPushBackEndRegistrationRequestData.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-21.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OmniaPushDictionaryizable.h"
#import "OmniaPushJsonizable.h"

OBJC_EXPORT NSString *const kReleaseUUID;
OBJC_EXPORT NSString *const kDeviceUUID;
OBJC_EXPORT NSString *const kReleaseSecret;
OBJC_EXPORT NSString *const kDeviceAlias;
OBJC_EXPORT NSString *const kDeviceManufacturer;
OBJC_EXPORT NSString *const kDeviceModel;
OBJC_EXPORT NSString *const kDeviceOS;
OBJC_EXPORT NSString *const kDeviceOSVersion;
OBJC_EXPORT NSString *const kRegistrationToken;

@interface OmniaPushBackEndRegistrationRequestData : NSObject<OmniaPushJsonizable, OmniaPushDictionaryizable>

@property (nonatomic) NSString *releaseUuid;
@property (nonatomic) NSString *secret;
@property (nonatomic) NSString *deviceAlias;
@property (nonatomic) NSString *deviceManufacturer;
@property (nonatomic) NSString *deviceModel;
@property (nonatomic) NSString *os;
@property (nonatomic) NSString *osVersion;
@property (nonatomic) NSString *registrationToken;

@end
