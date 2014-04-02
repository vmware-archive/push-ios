//
//  PCFAnalyticEvent.m
//  
//
//  Created by DX123-XL on 2014-03-28.
//
//

#import "PCFAnalyticEvent.h"
#import "PCFPushDebug.h"
#import "PCFPushCoreDataManager.h"
#import "PCFPushPersistentStorage.h"

static const struct EventRemoteAttributes {
    PCF_STRUCT_STRING *eventID;
    PCF_STRUCT_STRING *eventType;
    PCF_STRUCT_STRING *eventTime;
    PCF_STRUCT_STRING *variantUUID;
    PCF_STRUCT_STRING *eventData;
} EventRemoteAttributes;

static const struct EventRemoteAttributes EventRemoteAttributes = {
    .eventID      = @"id",
    .eventType    = @"type",
    .eventTime    = @"time",
    .variantUUID  = @"variant_uuid",
    .eventData    = @"data",
};

@interface PCFAnalyticEvent ()

@property (nonatomic, readwrite) NSString *eventType;
@property (nonatomic, readwrite) NSString *eventID;
@property (nonatomic, readwrite) NSString *eventTime;
@property (nonatomic, readwrite) NSString *variantUUID;
@property (nonatomic, readwrite) NSDictionary *eventData;

+ (void)logEventWithType:(NSString *)eventType;

@end

@implementation PCFAnalyticEvent

@dynamic eventID;
@dynamic eventType;
@dynamic eventTime;
@dynamic variantUUID;
@dynamic eventData;

+ (NSDictionary *)localToRemoteMapping
{
    static NSDictionary *localToRemoteMapping;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        localToRemoteMapping = @{
                                 PCF_STR_PROP(eventID)     : EventRemoteAttributes.eventID,
                                 PCF_STR_PROP(eventType)   : EventRemoteAttributes.eventType,
                                 PCF_STR_PROP(eventTime)   : EventRemoteAttributes.eventTime,
                                 PCF_STR_PROP(variantUUID) : EventRemoteAttributes.variantUUID,
                                 PCF_STR_PROP(eventData)   : EventRemoteAttributes.eventData,
                                 };
    });
    
    return localToRemoteMapping;
}

+ (void)logEventWithType:(NSString *)eventType
{
    [self logEventWithType:eventType eventData:nil];
}

+ (void)logEventWithType:(NSString *)eventType eventData:(NSDictionary *)eventData
{
    if (![PCFPushPersistentStorage analyticsEnabled]) {
        PCFPushLog(@"Analytics disabled. Event will not be logged.");
        return;
    }
    
    NSManagedObjectContext *context = [[PCFPushCoreDataManager shared] managedObjectContext];
    [context performBlock:^{
        NSEntityDescription *description = [NSEntityDescription entityForName:NSStringFromClass(self.class) inManagedObjectContext:context];
        PCFAnalyticEvent *event = [[self alloc] initWithEntity:description insertIntoManagedObjectContext:context];
        [event setEventID:[[NSUUID UUID] UUIDString]];
        [event setEventType:eventType];
        [event setVariantUUID:[PCFPushPersistentStorage variantUUID]];
        [event setEventTime:[NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970]]];
        
        if (eventData) {
            [event setEventData:eventData];
        }
        
        NSError *error;
        if (![context save:&error]) {
            PCFPushCriticalLog(@"Managed Object Context failed to save: %@ %@", error, error.userInfo);
        }
    }];
}

+ (void)logEventInitialized
{
    [self logEventWithType:@"event_initialized"];
}

+ (void)logEventAppActive
{
    [self logEventWithType:@"event_app_active"];
}

+ (void)logEventAppInactive
{
    [self logEventWithType:@"event_app_inactive"];
}

+ (void)logEventForeground
{
    [self logEventWithType:@"event_foregrounded"];
}

+ (void)logEventBackground
{
    [self logEventWithType:@"event_backgrounded"];
}

+ (void)logEventRegistered
{
    [self logEventWithType:@"event_registered"];
}

+ (void)logEventPushReceivedWithData:(NSDictionary *)eventData
{
    [self logEventWithType:@"event_push_received" eventData:eventData];
}

@end
