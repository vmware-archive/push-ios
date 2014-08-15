//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

static NSString *const KEY_APNS_DEVICE_TOKEN  = @"MSS_PUSH_APNS_DEVICE_TOKEN";
static NSString *const KEY_VARIANT_UUID       = @"MSS_PUSH_VARIANT_UUID";
static NSString *const KEY_VARIANT_SECRET     = @"MSS_PUSH_VARIANT_SECRET";
static NSString *const KEY_DEVICE_ALIAS       = @"MSS_PUSH_DEVICE_ALIAS";

#import "MSSPersistentStorage+Push.h"

@implementation MSSPersistentStorage (Push)

+ (void)resetPushPersistedValues
{
    [self reset];
    NSArray *keys = @[
                      KEY_APNS_DEVICE_TOKEN,
                      KEY_VARIANT_UUID,
                      KEY_VARIANT_SECRET,
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

+ (void)setVariantSecret:(NSString *)variantSecret
{
    [self persistValue:variantSecret forKey:KEY_VARIANT_SECRET];
}

+ (NSString *)variantSecret
{
    return [self persistedValueForKey:KEY_VARIANT_SECRET];
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
