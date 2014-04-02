//
//  PCFPushRegistrationParameters.m
//  PCFPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-21.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "PCFPushParameters.h"

@implementation PCFPushParameters

+ (instancetype)parametersWithNotificationTypes:(UIRemoteNotificationType)types
                                    variantUUID:(NSString *)variantUUID
                                  releaseSecret:(NSString *)releaseSecret
                                    deviceAlias:(NSString *)deviceAlias
{
    id registrationParams = [[PCFPushParameters alloc] initWithTypes:types
                                                         variantUUID:variantUUID
                                                       releaseSecret:releaseSecret
                                                         deviceAlias:deviceAlias];
    return registrationParams;
}

- (id)initWithTypes:(UIRemoteNotificationType)remoteNotificationTypes
        variantUUID:(NSString *)variantUUID
      releaseSecret:(NSString *)releaseSecret
        deviceAlias:(NSString *)deviceAlias
{
    self = [super init];
    
    if (self) {
        if (!variantUUID) {
            [NSException raise:NSInvalidArgumentException format:@"variantUUID may not be nil"];
        }
        if (!releaseSecret) {
            [NSException raise:NSInvalidArgumentException format:@"releaseSecret may not be nil"];
        }
        if (variantUUID.length <= 0) {
            [NSException raise:NSInvalidArgumentException format:@"releaseUuid may not be empty"];
        }
        if (releaseSecret.length <= 0) {
            [NSException raise:NSInvalidArgumentException format:@"releaseSecret may not be empty"];
        }
        if (!deviceAlias) {
            [NSException raise:NSInvalidArgumentException format:@"deviceAlias may not be nil"];
        }
        _remoteNotificationTypes = remoteNotificationTypes;
        _variantUUID = variantUUID;
        _releaseSecret = releaseSecret;
        _deviceAlias = deviceAlias;
    }
    
    return self;
}

@end
