//
//  PCFAnalyticEvent.h
//  
//
//  Created by DX123-XL on 2014-03-28.
//
//

#import <CoreData/CoreData.h>
#import "PCFPushMapping.h"
#import "PCFSortDescriptors.h"

const struct EventTypes {
    PCF_STRUCT_STRING *initialized;
    PCF_STRUCT_STRING *active;
    PCF_STRUCT_STRING *inactive;
    PCF_STRUCT_STRING *foregrounded;
    PCF_STRUCT_STRING *backgrounded;
    PCF_STRUCT_STRING *registered;
    PCF_STRUCT_STRING *received;
} EventTypes;

const struct EventRemoteAttributes {
    PCF_STRUCT_STRING *eventID;
    PCF_STRUCT_STRING *eventType;
    PCF_STRUCT_STRING *eventTime;
    PCF_STRUCT_STRING *variantUUID;
    PCF_STRUCT_STRING *eventData;
} EventRemoteAttributes;


@interface PCFAnalyticEvent : NSManagedObject <PCFPushMapping, PCFSortDescriptors>

@property (nonatomic, readonly) NSString *eventType;
@property (nonatomic, readonly) NSString *eventID;
@property (nonatomic, readonly) NSString *eventTime;
@property (nonatomic, readonly) NSString *variantUUID;
@property (nonatomic, readonly) NSDictionary *eventData;

+ (void)logEventInitialized;
+ (void)logEventAppActive;
+ (void)logEventAppInactive;
+ (void)logEventForeground;
+ (void)logEventBackground;
+ (void)logEventRegistered;
+ (void)logEventPushReceivedWithData:(NSDictionary *)eventData;

@end
