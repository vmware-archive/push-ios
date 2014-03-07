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

#ifndef STR_PROP
#define STR_PROP( prop ) NSStringFromSelector(@selector(prop))
#endif

@interface OmniaPushBackEndRegistrationData : NSObject <OmniaPushJsonizable, OmniaPushDictionaryizable>

@property (nonatomic) NSString *releaseUUID;
@property (nonatomic) NSString *deviceAlias;
@property (nonatomic) NSString *deviceManufacturer;
@property (nonatomic) NSString *deviceModel;
@property (nonatomic) NSString *os;
@property (nonatomic) NSString *osVersion;
@property (nonatomic) NSString *registrationToken;

+ (NSDictionary *)localToRemoteMapping;

@end
