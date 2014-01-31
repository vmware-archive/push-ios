//
//  Settings.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-31.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OmniaPushRegistrationParameters;

@interface Settings : NSObject

+ (NSString*) loadReleaseUuid;
+ (void) saveReleaseUuid:(NSString*)releaseUuid;

+ (NSString*) loadReleaseSecret;
+ (void) saveReleaseSecret:(NSString*)releaseSecret;

+ (NSString*) loadDeviceAlias;
+ (void) saveDeviceAlias:(NSString*)deviceAlias;

+ (void) resetToDefaults;

+ (OmniaPushRegistrationParameters*) getRegistrationParameters;
+ (NSDictionary*) getDefaults;

@end
