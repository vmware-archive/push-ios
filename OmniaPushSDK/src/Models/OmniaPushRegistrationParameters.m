//
//  OmniaPushRegistrationParameters.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-21.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "OmniaPushRegistrationParameters.h"

@interface OmniaPushRegistrationParameters ()

@property (nonatomic, readwrite) UIRemoteNotificationType remoteNotificationTypes;
@property (nonatomic, readwrite) NSString *releaseUUID;
@property (nonatomic, readwrite) NSString *releaseSecret;
@property (nonatomic, readwrite) NSString *deviceAlias;

@end

@implementation OmniaPushRegistrationParameters

+ (instancetype)parametersForNotificationTypes:(UIRemoteNotificationType)remoteNotificationTypes
                                   releaseUUID:(NSString *)releaseUUID
                                 releaseSecret:(NSString *)releaseSecret
                                   deviceAlias:(NSString *)deviceAlias
{
    OmniaPushRegistrationParameters *params = [[OmniaPushRegistrationParameters alloc] init];
    
    if (params) {
        if (!releaseUUID) {
            [NSException raise:NSInvalidArgumentException format:@"releaseUuid may not be nil"];
        }
        if (!releaseSecret) {
            [NSException raise:NSInvalidArgumentException format:@"releaseSecret may not be nil"];
        }
        if (releaseUUID.length <= 0) {
            [NSException raise:NSInvalidArgumentException format:@"releaseUuid may not be empty"];
        }
        if (releaseSecret.length <= 0) {
            [NSException raise:NSInvalidArgumentException format:@"releaseSecret may not be empty"];
        }
        if (!deviceAlias) {
            [NSException raise:NSInvalidArgumentException format:@"deviceAlias may not be nil"];
        }
        params.remoteNotificationTypes = remoteNotificationTypes;
        params.releaseUUID = releaseUUID;
        params.releaseSecret = releaseSecret;
        params.deviceAlias = deviceAlias;
    }
    return params;
}

@end
