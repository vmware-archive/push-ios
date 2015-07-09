//
// Created by DX173-XL on 2015-04-21.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PCFPushGeofenceEngine;

@interface PCFPushGeofenceUpdater : NSObject

+ (void)startGeofenceUpdate:(PCFPushGeofenceEngine *)engine
                   userInfo:(NSDictionary *)userInfo
                  timestamp:(int64_t)timestamp
                       tags:(NSSet *)subscribedTags
                    success:(void (^)(void))successBlock
                    failure:(void (^)(NSError *error))failureBlock;

+ (void)clearAllGeofences:(PCFPushGeofenceEngine *)engine;

@end