//
//  Settings.h
//  CFPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-31.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CFPushParameters;

@interface Settings : NSObject

+ (NSString *)releaseUUID;
+ (void)setReleaseUUID:(NSString *)releaseUUID;

+ (NSString *)releaseSecret;
+ (void)setReleaseSecret:(NSString *)releaseSecret;

+ (NSString *)deviceAlias;
+ (void)setDeviceAlias:(NSString *)deviceAlias;

+ (void)resetToDefaults;

+ (CFPushParameters *)registrationParameters;
+ (NSDictionary *)defaults;

@end
