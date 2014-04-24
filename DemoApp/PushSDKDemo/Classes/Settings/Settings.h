//
//  Settings.h
//  PCFPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-31.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PCFParameters;

@interface Settings : NSObject

+ (NSString *)variantUUID;
+ (void)setVariantUUID:(NSString *)variantUUID;

+ (NSString *)releaseSecret;
+ (void)setReleaseSecret:(NSString *)releaseSecret;

+ (NSString *)deviceAlias;
+ (void)setDeviceAlias:(NSString *)deviceAlias;

+ (void)resetToDefaults;

+ (PCFParameters *)registrationParameters;
+ (NSDictionary *)defaults;

@end
