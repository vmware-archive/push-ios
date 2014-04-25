//
//  PCFAnalyticEvent.h
//  
//
//  Created by DX123-XL on 2014-03-28.
//
//

#import <CoreData/CoreData.h>
#import "PCFMapping.h"
#import "PCFSortDescriptors.h"

const struct PushNotificationKeys {
    PCF_STRUCT_STRING *pushID;
    PCF_STRUCT_STRING *appState;
} PushNotificationKeys;

@interface PCFAnalyticEvent : NSManagedObject <PCFMapping, PCFSortDescriptors>

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
