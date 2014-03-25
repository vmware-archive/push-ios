//
//  OmniaPushBackEndRegistrationData.h
//  OmniaPushSDK
//
//  Created by DX123-XL on 3/7/2014.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OmniaPushDictionaryizable.h"
#import "OmniaPushJsonizable.h"

#ifndef OMNIA_STR_PROP
#define OMNIA_STR_PROP( prop ) NSStringFromSelector(@selector(prop))
#endif

@interface OmniaPushBackEndRegistrationData : NSObject <OmniaPushJsonizable, OmniaPushDictionaryizable>

@property NSString *releaseUUID;
@property NSString *deviceAlias;
@property NSString *deviceManufacturer;
@property NSString *deviceModel;
@property NSString *os;
@property NSString *osVersion;
@property NSString *registrationToken;

+ (NSDictionary *)localToRemoteMapping;

@end
