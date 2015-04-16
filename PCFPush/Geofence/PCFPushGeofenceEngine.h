//
// Created by DX181-XL on 15-04-15.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PCFPushGeofenceResponseData;

@interface PCFPushGeofenceEngine : NSObject

- (void) processResponseData:(PCFPushGeofenceResponseData*)responseData withTimestamp:(int64_t)timestamp;

@end