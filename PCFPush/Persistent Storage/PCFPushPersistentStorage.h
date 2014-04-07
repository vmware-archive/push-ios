//
//  PCFPushPersistentStorage.h
//  PCFPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-17.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PCFPushPersistentStorage : NSObject

+ (void)reset;

+ (void)setAPNSDeviceToken:(NSData *)apnsDeviceToken;
+ (NSData *)APNSDeviceToken;

+ (void)setPushServerDeviceID:(NSString *)backEndDeviceID;
+ (NSString *)pushServerDeviceID;

+ (void)setVariantUUID:(NSString *)variantUUID;
+ (NSString *)variantUUID;

+ (void)setReleaseSecret:(NSString *)releaseSecret;
+ (NSString *)releaseSecret;

+ (void)setDeviceAlias:(NSString *)deviceAlias;
+ (NSString *)deviceAlias;

+ (void)setAnalyticsEnabled:(BOOL)enabled;
+ (BOOL)analyticsEnabled;

@end
