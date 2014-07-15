//
//  MSSPersistentStorage+Push.h
//  MSSPush
//
//  Created by Rob Szumlakowski on 2014-01-17.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "MSSPersistentStorage.h"

@interface MSSPersistentStorage (Push)

+ (void)setAPNSDeviceToken:(NSData *)apnsDeviceToken;
+ (NSData *)APNSDeviceToken;

+ (void)setVariantUUID:(NSString *)variantUUID;
+ (NSString *)variantUUID;

+ (void)setReleaseSecret:(NSString *)releaseSecret;
+ (NSString *)releaseSecret;

+ (void)setDeviceAlias:(NSString *)deviceAlias;
+ (NSString *)deviceAlias;

+ (void)resetPushPersistedValues;

@end
