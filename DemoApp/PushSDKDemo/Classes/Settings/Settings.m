//
//  Settings.m
//  PCFPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-31.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "Settings.h"
#import "PCFPushParameters.h"

static NSString *const DEFAULT_VARIANT_UUID   = @"a5ca5693-f729-4e9a-8df2-65e02cebc852";
static NSString *const DEFAULT_RELEASE_SECRET = @"46e3382b-4e74-41c3-9fb0-e6867a96d8f3";
static NSString *const DEFAULT_DEVICE_ALIAS   = @"Default Device Alias";

static NSString *const KEY_VARIANT_UUID    = @"KEY_variant_uuid";
static NSString *const KEY_RELEASE_SECRET  = @"KEY_RELEASE_SECRET";
static NSString *const KEY_DEVICE_ALIAS    = @"KEY_DEVICE_ALIAS";

@implementation Settings

+ (NSString *)variantUUID
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:KEY_variant_uuid];
}

+ (void)setVariantUUID:(NSString *)variantUUID
{
    [[NSUserDefaults standardUserDefaults] setObject:variantUUID forKey:KEY_variant_uuid];
}

+ (NSString *)releaseSecret
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:KEY_RELEASE_SECRET];
}

+ (void)setReleaseSecret:(NSString *)releaseSecret
{
    [[NSUserDefaults standardUserDefaults] setObject:releaseSecret forKey:KEY_RELEASE_SECRET];
}

+ (NSString *)deviceAlias
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:KEY_DEVICE_ALIAS];
}

+ (void)setDeviceAlias:(NSString *)deviceAlias
{
    [[NSUserDefaults standardUserDefaults] setObject:deviceAlias forKey:KEY_DEVICE_ALIAS];
}

+ (void)resetToDefaults
{
    [self setVariantUUID:DEFAULT_VARIANT_UUID];
    [self setReleaseSecret:DEFAULT_RELEASE_SECRET];
    [self setDeviceAlias:DEFAULT_DEVICE_ALIAS];
}

+ (PCFPushParameters *)registrationParameters
{
    return [PCFPushParameters parametersWithNotificationTypes:UIRemoteNotificationTypeBadge|UIRemoteNotificationTypeSound|UIRemoteNotificationTypeAlert
                                                               variantUUID:[Settings variantUUID]
                                                             releaseSecret:[Settings releaseSecret]
                                                               deviceAlias:[Settings deviceAlias]];
}

+ (NSDictionary *)defaults
{
    return @{
             KEY_VARIANT_UUID : DEFAULT_VARIANT_UUID,
             KEY_RELEASE_SECRET : DEFAULT_RELEASE_SECRET,
             KEY_DEVICE_ALIAS : DEFAULT_DEVICE_ALIAS,
             };
}

@end
