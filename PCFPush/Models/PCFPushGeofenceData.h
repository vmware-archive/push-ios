//
//  PCFPushGeofenceData.h
//  PCFPush
//
//  Created by DX181-XL on 2015-04-14.
//  Copyright (c) 2015 Pivotal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PCFMapping.h"

typedef NS_ENUM(NSInteger, PCFPushTriggerType) {
    PCFPushTriggerTypeUndefined = 0,
    PCFPushTriggerTypeEnter,
    PCFPushTriggerTypeExit
};

@interface PCFPushGeofenceData : NSObject <PCFMapping>

@property int64_t id;
@property NSDate *expiryTime;
@property NSArray *locations;
@property NSDictionary *data;
@property NSSet<NSString*> *tags;
@property PCFPushTriggerType triggerType;

- (instancetype)newCopyWithoutLocations;

- (BOOL)isEqual:(id)other;

- (BOOL)isEqualToData:(PCFPushGeofenceData *)data;

- (NSUInteger)hash;

@end
