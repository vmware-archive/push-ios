//
//  PMSSPersistentStorage.m
//  
//
//  Created by DX123-XL on 2014-04-25.
//
//

#import "PMSSPersistentStorage.h"

static NSString *const KEY_BACK_END_DEVICE_ID = @"PMSS_PUSH_BACK_END_DEVICE_ID";

@implementation PMSSPersistentStorage

+ (void)reset
{
    [self removeObjectForKey:KEY_BACK_END_DEVICE_ID];
}

+ (void)setServerDeviceID:(NSString *)backEndDeviceID
{
    [self persistValue:backEndDeviceID forKey:KEY_BACK_END_DEVICE_ID];
}

+ (NSString *)serverDeviceID
{
    return [self persistedValueForKey:KEY_BACK_END_DEVICE_ID];
}

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
