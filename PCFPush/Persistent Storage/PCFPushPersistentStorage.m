//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "PCFPushPersistentStorage.h"

static NSString *const KEY_BACK_END_DEVICE_ID           = @"PCF_PUSH_BACK_END_DEVICE_ID";
static NSString *const KEY_APNS_DEVICE_TOKEN            = @"PCF_PUSH_APNS_DEVICE_TOKEN";
static NSString *const KEY_VARIANT_UUID                 = @"PCF_PUSH_VARIANT_UUID";
static NSString *const KEY_VARIANT_SECRET               = @"PCF_PUSH_VARIANT_SECRET";
static NSString *const KEY_DEVICE_ALIAS                 = @"PCF_PUSH_DEVICE_ALIAS";
static NSString *const KEY_TAGS                         = @"PCF_PUSH_TAGS";
static NSString *const KEY_GEOFENCES_LAST_MODIFIED_TIME = @"PCF_PUSH_GEOFENCES_LAST_MODIFIED_TIME";
static NSString *const KEY_ARE_GEOFENCES_ENABLED        = @"PCF_PUSH_ARE_GEOFENCES_ENABLED";
static NSString *const KEY_REQUEST_HEADERS              = @"PCF_PUSH_REQUEST_HEADERS";
static NSString *const KEY_SERVER_VERSION               = @"PCF_PUSH_SERVER_VERSION";
static NSString *const KEY_SERVER_VERSION_TIME_POLLED   = @"PCF_PUSH_SERVER_VERSION_TIME_POLLED";

@implementation PCFPushPersistentStorage

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

+ (void)reset
{
    NSArray *keys = @[
                      KEY_BACK_END_DEVICE_ID,
                      KEY_APNS_DEVICE_TOKEN,
                      KEY_VARIANT_UUID,
                      KEY_VARIANT_SECRET,
                      KEY_DEVICE_ALIAS,
                      KEY_TAGS,
                      KEY_GEOFENCES_LAST_MODIFIED_TIME,
                      KEY_ARE_GEOFENCES_ENABLED,
                      KEY_REQUEST_HEADERS,
                      KEY_SERVER_VERSION,
                      KEY_SERVER_VERSION_TIME_POLLED,
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

+ (void)setServerDeviceID:(NSString *)serverDeviceID
{
    [self persistValue:serverDeviceID forKey:KEY_BACK_END_DEVICE_ID];
}

+ (NSString *)serverDeviceID
{
    return [self persistedValueForKey:KEY_BACK_END_DEVICE_ID];
}

+ (void)setTags:(NSSet<NSString*> *)tags
{
    [self persistValue:tags.allObjects forKey:KEY_TAGS];
}

+ (NSSet<NSString*> *)tags
{
    NSArray<NSString*> *tagsArray = [self persistedValueForKey:KEY_TAGS];
    if (tagsArray) {
        return [NSSet<NSString*> setWithArray:tagsArray];
    } else {
        return nil;
    }
}

+ (int64_t)lastGeofencesModifiedTime
{
    id value = [self persistedValueForKey:KEY_GEOFENCES_LAST_MODIFIED_TIME];
    if (value == nil) {
        return PCF_NEVER_UPDATED_GEOFENCES;
    } else {
        return [value longLongValue];
    }
}

+ (void)setGeofenceLastModifiedTime:(int64_t)lastModifiedTime
{
    [self persistValue:@(lastModifiedTime) forKey:KEY_GEOFENCES_LAST_MODIFIED_TIME];
}

+ (BOOL)areGeofencesEnabled
{
    return [[self persistedValueForKey:KEY_ARE_GEOFENCES_ENABLED] boolValue];
}

+ (void)setAreGeofencesEnabled:(BOOL)areGeofencesEnabled
{
    [self persistValue:@(areGeofencesEnabled) forKey:KEY_ARE_GEOFENCES_ENABLED];
}

+ (void)setRequestHeaders:(NSDictionary *)requestHeaders
{
    [self persistValue:requestHeaders forKey:KEY_REQUEST_HEADERS];
}

+ (NSDictionary *)requestHeaders
{
    return [self persistedValueForKey:KEY_REQUEST_HEADERS];
}

+ (void)setServerVersion:(NSString*)version
{
    [self persistValue:version forKey:KEY_SERVER_VERSION];
}

+ (NSString*)serverVersion
{
    return [self persistedValueForKey:KEY_SERVER_VERSION];
}

+ (void)setServerVersionTimePolled:(NSDate*)timestamp
{
    [self persistValue:timestamp forKey:KEY_SERVER_VERSION_TIME_POLLED];
}

+ (NSDate*)serverVersionTimePolled
{
    return [self persistedValueForKey:KEY_SERVER_VERSION_TIME_POLLED];
}

@end
