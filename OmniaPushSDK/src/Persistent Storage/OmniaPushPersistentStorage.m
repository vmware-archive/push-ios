//
//  OmniaPushPersistentStorage.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-17.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#define KEY_APNS_DEVICE_TOKEN   @"OMNIA_PUSH_APNS_DEVICE_TOKEN"
#define KEY_BACK_END_DEVICE_ID  @"OMNIA_PUSH_BACK_END_DEVICE_ID"

#import "OmniaPushPersistentStorage.h"

@implementation OmniaPushPersistentStorage

- (void) reset
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:KEY_APNS_DEVICE_TOKEN];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:KEY_BACK_END_DEVICE_ID];
}

- (void) saveAPNSDeviceToken:(NSData*)apnsDeviceToken
{
    [[NSUserDefaults standardUserDefaults] setObject:apnsDeviceToken forKey:KEY_APNS_DEVICE_TOKEN];
}

- (NSData*) loadAPNSDeviceToken
{
    return [[NSUserDefaults standardUserDefaults] dataForKey:KEY_APNS_DEVICE_TOKEN];
}

- (void) saveBackEndDeviceID:(NSString*)backEndDeviceId
{
    [[NSUserDefaults standardUserDefaults] setObject:backEndDeviceId forKey:KEY_BACK_END_DEVICE_ID];
}

- (NSString*) loadBackEndDeviceID
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:KEY_BACK_END_DEVICE_ID];
}

@end
