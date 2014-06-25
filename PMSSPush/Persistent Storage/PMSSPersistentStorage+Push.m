//
//  PMSSPushPersistentStorage.m
//  PMSSPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-17.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

static NSString *const KEY_APNS_DEVICE_TOKEN  = @"PMSS_PUSH_APNS_DEVICE_TOKEN";
static NSString *const KEY_VARIANT_UUID       = @"PMSS_PUSH_VARIANT_UUID";
static NSString *const KEY_RELEASE_SECRET     = @"PMSS_PUSH_RELEASE_SECRET";
static NSString *const KEY_DEVICE_ALIAS       = @"PMSS_PUSH_DEVICE_ALIAS";

#import "PMSSPersistentStorage+Push.h"

@implementation PMSSPersistentStorage (Push)

+ (void)resetPushPersistedValues
{
    [self reset];
    NSArray *keys = @[
                      KEY_APNS_DEVICE_TOKEN,
                      KEY_VARIANT_UUID,
                      KEY_RELEASE_SECRET,
                      KEY_DEVICE_ALIAS,
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

@end
