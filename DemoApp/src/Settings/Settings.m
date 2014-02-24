//
//  Settings.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-31.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import "Settings.h"
#import "OmniaPushRegistrationParameters.h"

static NSString *const DEFAULT_RELEASE_UUID   = @"a5ca5693-f729-4e9a-8df2-65e02cebc852";
static NSString *const DEFAULT_RELEASE_SECRET = @"46e3382b-4e74-41c3-9fb0-e6867a96d8f3"
static NSString *const DEFAULT_DEVICE_ALIAS   = @"Default Device Alias"

static NSString *const KEY_RELEASE_UUID    = @"KEY_RELEASE_UUID";
static NSString *const KEY_RELEASE_SECRET  = @"KEY_RELEASE_SECRET";
static NSString *const KEY_DEVICE_ALIAS    = @"KEY_DEVICE_ALIAS";

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
    return [[OmniaPushRegistrationParameters alloc] initForNotificationTypes:UIRemoteNotificationTypeBadge|UIRemoteNotificationTypeSound|UIRemoteNotificationTypeAlert
                                                                 releaseUuid:[Settings loadReleaseUuid]
                                                               releaseSecret:[Settings loadReleaseSecret]
                                                                 deviceAlias:[Settings loadDeviceAlias]];
}

+ (NSDictionary*) getDefaults
{
    return @{
             KEY_RELEASE_UUID : DEFAULT_RELEASE_UUID,
             KEY_RELEASE_SECRET : DEFAULT_RELEASE_SECRET,
             KEY_DEVICE_ALIAS : DEFAULT_DEVICE_ALIAS,
             };
}

@end
