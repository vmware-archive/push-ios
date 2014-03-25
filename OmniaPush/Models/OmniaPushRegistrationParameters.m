//
//  OmniaPushRegistrationParameters.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-21.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "OmniaPushRegistrationParameters.h"

@implementation OmniaPushRegistrationParameters

+ (instancetype)parametersForNotificationTypes:(UIRemoteNotificationType)types
                                   releaseUUID:(NSString *)releaseUUID
                                 releaseSecret:(NSString *)releaseSecret
                                   deviceAlias:(NSString *)deviceAlias
{
    id registrationParams = [[OmniaPushRegistrationParameters alloc] initWithTypes:types releaseUUID:releaseUUID releaseSecret:releaseSecret deviceAlias:deviceAlias];
    return registrationParams;
}

- (id)initWithTypes:(UIRemoteNotificationType)remoteNotificationTypes
        releaseUUID:(NSString *)releaseUUID
      releaseSecret:(NSString *)releaseSecret
        deviceAlias:(NSString *)deviceAlias
{
    self = [super init];
    
    if (self) {
        if (!releaseUUID) {
            [NSException raise:NSInvalidArgumentException format:@"releaseUUID may not be nil"];
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
        _remoteNotificationTypes = remoteNotificationTypes;
        _releaseUUID = releaseUUID;
        _releaseSecret = releaseSecret;
        _deviceAlias = deviceAlias;
    }
    
    return self;
}

@end
