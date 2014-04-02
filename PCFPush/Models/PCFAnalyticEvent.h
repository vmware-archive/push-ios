//
//  PCFAnalyticEvent.h
//  
//
//  Created by DX123-XL on 2014-03-28.
//
//

#import <CoreData/CoreData.h>
#import "PCFPushMapping.h"

@interface PCFAnalyticEvent : NSManagedObject <PCFPushMapping>

@property (nonatomic, readonly) NSString *eventType;
@property (nonatomic, readonly) NSString *eventID;
@property (nonatomic, readonly) NSString *eventTime;
@property (nonatomic, readonly) NSDictionary *eventData;

+ (void)logEventInitialized;
+ (void)logEventAppActive;
+ (void)logEventAppInactive;
+ (void)logEventForeground;
+ (void)logEventBackground;
+ (void)logEventRegistered;
+ (void)logEventPushReceivedWithData:(NSDictionary *)eventData;

@end
