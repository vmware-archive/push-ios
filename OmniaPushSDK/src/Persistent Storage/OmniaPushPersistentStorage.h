//
//  OmniaPushPersistentStorage.h
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-17.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OmniaPushPersistentStorage : NSObject

- (void) reset;

- (void) saveAPNSDeviceToken:(NSData*)apnsDeviceToken;
- (NSData*) loadAPNSDeviceToken;

- (void) saveBackEndDeviceID:(NSString*)backEndDeviceId;
- (NSString*) loadBackEndDeviceID;

- (void) saveReleaseUuid:(NSString*)releaseUuid;
- (NSString*) loadReleaseUuid;

- (void) saveReleaseSecret:(NSString*)releaseSecret;
- (NSString*) loadReleaseSecret;

- (void) saveDeviceAlias:(NSString*)deviceAlias;
- (NSString*) loadDeviceAlias;

@end
