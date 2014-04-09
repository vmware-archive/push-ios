//
//  PCFPushPersistentStorage.m
//  PCFPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-17.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

static NSString *const KEY_APNS_DEVICE_TOKEN  = @"PCF_PUSH_APNS_DEVICE_TOKEN";
static NSString *const KEY_BACK_END_DEVICE_ID = @"PCF_PUSH_BACK_END_DEVICE_ID";
static NSString *const KEY_VARIANT_UUID       = @"PCF_PUSH_VARIANT_UUID";
static NSString *const KEY_RELEASE_SECRET     = @"PCF_PUSH_RELEASE_SECRET";
static NSString *const KEY_DEVICE_ALIAS       = @"PCF_PUSH_DEVICE_ALIAS";
static NSString *const KEY_ANALYTICS_ENABLED  = @"PCF_KEY_ANALYTICS_ENABLED";

#import "PCFPushPersistentStorage.h"
#import "PCFPushRegistrationResponseData.h"

@implementation PCFPushPersistentStorage

+ (void)reset
{
    NSArray *keys = @[
                      KEY_APNS_DEVICE_TOKEN,
                      KEY_BACK_END_DEVICE_ID,
                      KEY_VARIANT_UUID,
                      KEY_RELEASE_SECRET,
                      KEY_DEVICE_ALIAS,
                      KEY_ANALYTICS_ENABLED,
                      ];
    
    [keys enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
        [self removeObjectForKey:key];
    }];
}

+ (void)setAPNSDeviceToken:(NSData *)apnsDeviceToken
{
    [self persistValue:apnsDeviceToken forKey:KEY_APNS_DEVICE_TOKEN];
}

+ (NSData *)APNSDeviceToken
{
    return [self persistedValueForKey:KEY_APNS_DEVICE_TOKEN];
}

+ (void)setPushServerDeviceID:(NSString *)backEndDeviceID
{
    [self persistValue:backEndDeviceID forKey:KEY_BACK_END_DEVICE_ID];
}

+ (NSString *)pushServerDeviceID
{
    return [self persistedValueForKey:KEY_BACK_END_DEVICE_ID];
}

+ (void)setVariantUUID:(NSString *)variantUUID
{
    [self persistValue:variantUUID forKey:KEY_VARIANT_UUID];
}

+ (NSString *)variantUUID
{
    return [self persistedValueForKey:KEY_VARIANT_UUID];
}

+ (void)setReleaseSecret:(NSString *)releaseSecret
{
    [self persistValue:releaseSecret forKey:KEY_RELEASE_SECRET];
}

+ (NSString *)releaseSecret
{
    return [self persistedValueForKey:KEY_RELEASE_SECRET];
}

+ (void)setDeviceAlias:(NSString *)deviceAlias
{
    [self persistValue:deviceAlias forKey:KEY_DEVICE_ALIAS];
}

+ (NSString *)deviceAlias
{
    return [self persistedValueForKey:KEY_DEVICE_ALIAS];
}

+ (void)setAnalyticsEnabled:(BOOL)enabled
{
    [self persistValue:[NSNumber numberWithBool:enabled] forKey:KEY_ANALYTICS_ENABLED];
}

+ (BOOL)analyticsEnabled
{
    NSNumber *enabled = [self persistedValueForKey:KEY_ANALYTICS_ENABLED];
    if (!enabled) {
        BOOL defaultValue = NO;
        [self setAnalyticsEnabled:defaultValue];
        return defaultValue;
    }
    return [enabled boolValue];
}

#pragma mark - Persistence Methods

+ (void)persistValue:(id)value forKey:(id)key
{
    [[NSUserDefaults standardUserDefaults] setValue:value forKey:key];
}

+ (id)persistedValueForKey:(id)key
{
    return [[NSUserDefaults standardUserDefaults] valueForKey:key];
}

+ (void)removeObjectForKey:(id)key
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
}

@end
