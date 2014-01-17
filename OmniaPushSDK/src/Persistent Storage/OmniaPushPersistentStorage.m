//
//  OmniaPushPersistentStorage.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-17.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#define KEY_DEVICE_TOKEN @"DEVICE_TOKEN"

#import "OmniaPushPersistentStorage.h"

@implementation OmniaPushPersistentStorage

- (void) reset
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:KEY_DEVICE_TOKEN];
}

- (void) saveDeviceToken:(NSData*)deviceToken
{
    [[NSUserDefaults standardUserDefaults] setObject:deviceToken forKey:KEY_DEVICE_TOKEN];
}

- (NSData*) loadDeviceToken
{
    return [[NSUserDefaults standardUserDefaults] dataForKey:KEY_DEVICE_TOKEN];
}

@end
