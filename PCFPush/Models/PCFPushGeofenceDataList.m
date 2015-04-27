//
// Created by DX181-XL on 15-04-16.
// Copyright (c) 2015 Pivotal. All rights reserved.
//

#import "PCFPushGeofenceDataList.h"
#import "NSObject+PCFJSONizable.h"
#import "PCFPushGeofenceData.h"

@interface PCFPushGeofenceDataList ()

@property (nonatomic) NSMutableDictionary *dict;

@end

@implementation PCFPushGeofenceDataList

+ (instancetype) list
{
    return [[PCFPushGeofenceDataList alloc] init];
}

- (instancetype) init
{
    self = [super init];
    if (self) {
        self.dict = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSUInteger) count
{
    return self.dict.count;
}

- (BOOL)isEqual:(id)o {
    if (![o isKindOfClass:[PCFPushGeofenceDataList class]]) {
        return NO;
    }
    PCFPushGeofenceDataList *other = (PCFPushGeofenceDataList *)o;
    return [other.dict isEqual:self.dict];
}

- (void)addEntriesFromDictionary:(NSDictionary *)dict
{
    [self.dict addEntriesFromDictionary:dict];
}

- (id)objectForKeyedSubscript:(id <NSCopying>)key
{
    return self.dict[key];
}

- (void)setObject:(id)obj forKeyedSubscript:(id <NSCopying>)key
{
    self.dict[key] = obj;
}

- (void)enumerateKeysAndObjectsUsingBlock:(void (^)(int64_t id, PCFPushGeofenceData *geofence, BOOL *stop))block
{
    [self.dict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        block([key longLongValue], (PCFPushGeofenceData *)obj, stop);
    }];
}

@end