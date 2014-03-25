//
//  OmniaPushPersistentStorage.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-17.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

static NSString *const KEY_APNS_DEVICE_TOKEN  = @"OMNIA_PUSH_APNS_DEVICE_TOKEN";
static NSString *const KEY_BACK_END_DEVICE_ID = @"OMNIA_PUSH_BACK_END_DEVICE_ID";
static NSString *const KEY_RELEASE_UUID       = @"OMNIA_PUSH_RELEASE_UUID";
static NSString *const KEY_RELEASE_SECRET     = @"OMNIA_PUSH_RELEASE_SECRET";
static NSString *const KEY_DEVICE_ALIAS       = @"OMNIA_PUSH_DEVICE_ALIAS";

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

+ (void)setAPNSDeviceToken:(NSData *)apnsDeviceToken
{
    [[NSUserDefaults standardUserDefaults] setObject:apnsDeviceToken forKey:KEY_APNS_DEVICE_TOKEN];
}

+ (NSData *)APNSDeviceToken
{
    return [[NSUserDefaults standardUserDefaults] valueForKey:KEY_APNS_DEVICE_TOKEN];
}

+ (void)setBackEndDeviceID:(NSString *)backEndDeviceID
{
    [[NSUserDefaults standardUserDefaults] setObject:backEndDeviceID forKey:KEY_BACK_END_DEVICE_ID];
}

+ (NSString *)backEndDeviceID
{
    return [[NSUserDefaults standardUserDefaults] valueForKey:KEY_BACK_END_DEVICE_ID];
}

+ (void)setReleaseUUID:(NSString *)releaseUUID
{
    [[NSUserDefaults standardUserDefaults] setObject:releaseUUID forKey:KEY_RELEASE_UUID];
}

+ (NSString *)releaseUUID
{
    return [[NSUserDefaults standardUserDefaults] valueForKey:KEY_RELEASE_UUID];
}

+ (void)setReleaseSecret:(NSString *)releaseSecret
{
    [[NSUserDefaults standardUserDefaults] setObject:releaseSecret forKey:KEY_RELEASE_SECRET];
}

+ (NSString *)releaseSecret
{
    return [[NSUserDefaults standardUserDefaults] valueForKey:KEY_RELEASE_SECRET];
}

+ (void)setDeviceAlias:(NSString *)deviceAlias
{
    [[NSUserDefaults standardUserDefaults] setObject:deviceAlias forKey:KEY_DEVICE_ALIAS];
}

+ (NSString *)deviceAlias
{
    return [[NSUserDefaults standardUserDefaults] valueForKey:KEY_DEVICE_ALIAS];
}

@end
