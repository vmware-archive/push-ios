//
//  Settings.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-31.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import "Settings.h"
#import "OmniaPushRegistrationParameters.h"

#define DEFAULT_RELEASE_UUID    @"0e98c4aa-786e-4675-b2e3-05e5d040ab38"
#define DEFAULT_RELEASE_SECRET  @"5f2009b5-bb6a-4963-8abf-a18a2162929b"
#define DEFAULT_DEVICE_ALIAS    @"Default Device Alias"

#define KEY_RELEASE_UUID   @"KEY_RELEASE_UUID"
#define KEY_RELEASE_SECRET @"KEY_RELEASE_SECRET"
#define KEY_DEVICE_ALIAS   @"KEY_DEVICE_ALIAS"

@implementation Settings

+ (NSString*) loadReleaseUuid
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:KEY_RELEASE_UUID];
}

+ (void) saveReleaseUuid:(NSString*)releaseUuid
{
    [[NSUserDefaults standardUserDefaults] setObject:releaseUuid forKey:KEY_RELEASE_UUID];
}

+ (NSString*) loadReleaseSecret
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:KEY_RELEASE_SECRET];
}

+ (void) saveReleaseSecret:(NSString*)releaseSecret
{
    [[NSUserDefaults standardUserDefaults] setObject:releaseSecret forKey:KEY_RELEASE_SECRET];
}

+ (NSString*) loadDeviceAlias
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:KEY_DEVICE_ALIAS];
}

+ (void) saveDeviceAlias:(NSString*)deviceAlias
{
    [[NSUserDefaults standardUserDefaults] setObject:deviceAlias forKey:KEY_DEVICE_ALIAS];
}

+ (void) resetToDefaults
{
    [self saveReleaseUuid:DEFAULT_RELEASE_UUID];
    [self saveReleaseSecret:DEFAULT_RELEASE_SECRET];
    [self saveDeviceAlias:DEFAULT_DEVICE_ALIAS];
}

+ (OmniaPushRegistrationParameters*) getRegistrationParameters
{
    return [[OmniaPushRegistrationParameters alloc] initForNotificationTypes:UIRemoteNotificationTypeBadge
                                                                 releaseUuid:[Settings loadReleaseUuid]
                                                               releaseSecret:[Settings loadReleaseSecret]
                                                                 deviceAlias:[Settings loadDeviceAlias]];
}

+ (NSDictionary*) getDefaults
{
    return @{ KEY_RELEASE_UUID : DEFAULT_RELEASE_UUID,
              KEY_RELEASE_SECRET : DEFAULT_RELEASE_SECRET,
              KEY_DEVICE_ALIAS : DEFAULT_DEVICE_ALIAS };
}

@end
