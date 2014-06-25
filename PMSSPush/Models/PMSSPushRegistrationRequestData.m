//
//  PMSSPushBackEndRegistrationRequestData.m
//  PMSSPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-21.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "PMSSPushRegistrationRequestData.h"

NSString *const kReleaseSecret = @"secret";

@implementation PMSSPushRegistrationRequestData

+ (NSDictionary *)localToRemoteMapping
{
    static NSDictionary *localToRemoteMapping;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableDictionary *mapping = [NSMutableDictionary dictionaryWithDictionary:[super localToRemoteMapping]];
        [mapping setObject:kReleaseSecret forKey:PMSS_STR_PROP(secret)];
        localToRemoteMapping = [NSDictionary dictionaryWithDictionary:mapping];
    });
    
    return localToRemoteMapping;
}

@end
