//
//  OmniaPushPersistentStorage.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-17.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#define KEY_APNS_DEVICE_TOKEN @"OMNIA_PUSH_APNS_DEVICE_TOKEN"

#import "OmniaPushPersistentStorage.h"

@implementation OmniaPushPersistentStorage

- (void) reset
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:KEY_APNS_DEVICE_TOKEN];
}

- (void) saveAPNSDeviceToken:(NSData*)apnsDeviceToken
{
    [[NSUserDefaults standardUserDefaults] setObject:apnsDeviceToken forKey:KEY_APNS_DEVICE_TOKEN];
}

- (NSData*) loadAPNSDeviceToken
{
    return [[NSUserDefaults standardUserDefaults] dataForKey:KEY_APNS_DEVICE_TOKEN];
}

@end
