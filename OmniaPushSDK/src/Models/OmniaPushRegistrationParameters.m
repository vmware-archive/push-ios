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
@property (nonatomic, readwrite) NSString *releaseUuid;
@property (nonatomic, readwrite) NSString *releaseSecret;
@property (nonatomic, readwrite) NSString *deviceAlias;

@end

@implementation OmniaPushRegistrationParameters

+ (instancetype) parametersForNotificationTypes:(UIRemoteNotificationType)remoteNotificationTypes
                                    releaseUuid:(NSString*)releaseUuid
                                  releaseSecret:(NSString*)releaseSecret
                                    deviceAlias:(NSString*)deviceAlias
{
    OmniaPushRegistrationParameters *params = [super init];
    if (params) {
        if (releaseUuid == nil) {
            [NSException raise:NSInvalidArgumentException format:@"releaseUuid may not be nil"];
        }
        if (releaseSecret == nil) {
            [NSException raise:NSInvalidArgumentException format:@"releaseSecret may not be nil"];
        }
        if (releaseUuid.length <= 0) {
            [NSException raise:NSInvalidArgumentException format:@"releaseUuid may not be empty"];
        }
        if (releaseSecret.length <= 0) {
            [NSException raise:NSInvalidArgumentException format:@"releaseSecret may not be empty"];
        }
        if (deviceAlias == nil) {
            [NSException raise:NSInvalidArgumentException format:@"deviceAlias may not be nil"];
        }
        params.remoteNotificationTypes = remoteNotificationTypes;
        params.releaseUuid = releaseUuid;
        params.releaseSecret = releaseSecret;
        params.deviceAlias = deviceAlias;
    }
    return params;
}

@end
