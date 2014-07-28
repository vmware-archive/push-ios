//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MSSMapping.h"

@interface MSSPushRegistrationData : NSObject <MSSMapping>

@property NSString *variantUUID;
@property NSString *deviceAlias;
@property NSString *deviceManufacturer;
@property NSString *deviceModel;
@property NSString *os;
@property NSString *osVersion;
@property NSString *registrationToken;
@property NSArray *tags;

+ (NSDictionary *)localToRemoteMapping;

@end
