//
//  OmniaPushPersistentStorage.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-17.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

static NSString *const KEY_APNS_DEVICE_TOKEN = @"OMNIA_PUSH_APNS_DEVICE_TOKEN";
static NSString *const KEY_BACK_END_DEVICE_ID = @"OMNIA_PUSH_BACK_END_DEVICE_ID";
static NSString *const KEY_RELEASE_UUID = @"OMNIA_PUSH_RELEASE_UUID";
static NSString *const KEY_RELEASE_SECRET = @"OMNIA_PUSH_RELEASE_SECRET";
static NSString *const KEY_DEVICE_ALIAS = @"OMNIA_PUSH_DEVICE_ALIAS";

#import "OmniaPushPersistentStorage.h"
#import "OmniaPushBackEndRegistrationResponseData.h"

@implementation OmniaPushPersistentStorage

+ (void)reset
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:KEY_APNS_DEVICE_TOKEN];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:KEY_BACK_END_DEVICE_ID];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:KEY_RELEASE_UUID];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:KEY_RELEASE_SECRET];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:KEY_DEVICE_ALIAS];
}

+ (void)saveAPNSDeviceToken:(NSData *)apnsDeviceToken
{
    [[NSUserDefaults standardUserDefaults] setObject:apnsDeviceToken forKey:KEY_APNS_DEVICE_TOKEN];
}

+ (NSData *)loadAPNSDeviceToken
{
    return [[NSUserDefaults standardUserDefaults] dataForKey:KEY_APNS_DEVICE_TOKEN];
}

+ (void) saveBackEndDeviceID:(NSString*)backEndDeviceId
{
    [[NSUserDefaults standardUserDefaults] setObject:backEndDeviceId forKey:KEY_BACK_END_DEVICE_ID];
}

+ (NSString *)loadBackEndDeviceID
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:KEY_BACK_END_DEVICE_ID];
}

+ (void) saveReleaseUuid:(NSString*)releaseUuid
{
    [[NSUserDefaults standardUserDefaults] setObject:releaseUuid forKey:KEY_RELEASE_UUID];
}

+ (NSString *)loadReleaseUuid
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:KEY_RELEASE_UUID];
}

+ (void) saveReleaseSecret:(NSString*)releaseSecret
{
    [[NSUserDefaults standardUserDefaults] setObject:releaseSecret forKey:KEY_RELEASE_SECRET];
}

+ (NSString *)loadReleaseSecret
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:KEY_RELEASE_SECRET];
}

+ (void) saveDeviceAlias:(NSString*)deviceAlias
{
    [[NSUserDefaults standardUserDefaults] setObject:deviceAlias forKey:KEY_DEVICE_ALIAS];
}

+ (NSString *)loadDeviceAlias
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:KEY_DEVICE_ALIAS];
}

@end
