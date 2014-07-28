//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "MSSAnalytics.h"

@interface MSSAnalytics (TestingHeader)

+ (BOOL)shouldSendAnalytics;

+ (NSUInteger)maxStoredEventCount;
+ (void)setMaxStoredEventCount:(NSUInteger)maxCount;

+ (NSUInteger)maxBatchSize;
+ (void)setMaxBatchSize:(NSUInteger)batchSize;

+ (NSTimeInterval)minSecondsBetweenSends;
+ (void)setMinSecondsBetweenSends:(NSTimeInterval)minSeconds;

+ (NSTimeInterval)lastSendTime;
+ (void)setLastSendTime:(NSTimeInterval)sendTime;

+ (void)insertIntoContext:(NSManagedObjectContext *)context
            eventWithType:(NSString *)eventType
                     data:(NSDictionary *)eventData;

@end
