//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#define PCF_NEVER_UPDATED_GEOFENCES -1

@interface PCFPushPersistentStorage : NSObject

+ (void)setAPNSDeviceToken:(NSData *)apnsDeviceToken;
+ (NSData *)APNSDeviceToken;

+ (void)setVariantUUID:(NSString *)variantUUID;
+ (NSString *)variantUUID;

+ (void)setVariantSecret:(NSString *)variantSecret;
+ (NSString *)variantSecret;

+ (void)setDeviceAlias:(NSString *)deviceAlias;
+ (NSString *)deviceAlias;

+ (void)setServerDeviceID:(NSString *)serverDeviceID;
+ (NSString *)serverDeviceID;

+ (void)setTags:(NSSet *)tags;
+ (NSSet *)tags;

+ (void)setGeofenceLastModifiedTime:(int64_t)lastModifiedTime;
+ (int64_t)lastGeofencesModifiedTime;

+ (void)setAreGeofencesEnabled:(BOOL)areGeofencesEnabled;
+ (BOOL)areGeofencesEnabled;

+ (void)setRequestHeaders:(NSDictionary *)requestHeaders;
+ (NSDictionary *)requestHeaders;

+ (void)setServerVersion:(NSString*)version;
+ (NSString*)serverVersion;

+ (void)setServerVersionTimePolled:(NSDate*)timestamp;
+ (NSDate*)serverVersionTimePolled;

+ (void)reset;

@end
