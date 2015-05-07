//
//  PCFPushGeofenceLocation.h
//  PCFPush
//
//  Created by DX181-XL on 2015-04-14.
//  Copyright (c) 2015 Pivotal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PCFMapping.h"

@interface PCFPushGeofenceLocation : NSObject <PCFMapping>

@property int64_t id;
@property NSString *name;
@property double latitude;
@property double longitude;
@property double radius;

- (BOOL)isEqual:(id)other;

- (BOOL)isEqualToLocation:(PCFPushGeofenceLocation *)location;

- (NSUInteger)hash;

@end
