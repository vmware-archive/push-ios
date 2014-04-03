//
//  PCFAnalyticEvent.m
//  
//
//  Created by DX123-XL on 2014-03-28.
//
//

#import "PCFAnalyticEvent.h"
#import "PCFPushDebug.h"
#import "PCFCoreDataManager.h"
#import "PCFPushPersistentStorage.h"

const struct EventTypes EventTypes = {
    .initialized  = @"event_initialized",
    .active       = @"event_app_active",
    .inactive     = @"event_app_inactive",
    .foregrounded = @"event_foregrounded",
    .backgrounded = @"event_backgrounded",
    .registered   = @"event_registered",
    .received     = @"event_push_received",
};

const struct EventRemoteAttributes EventRemoteAttributes = {
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

#pragma mark - Event Database Logging

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
    
    NSManagedObjectContext *context = [[PCFCoreDataManager shared] managedObjectContext];
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
    [self logEventWithType:EventTypes.initialized];
}

+ (void)logEventAppActive
{
    [self logEventWithType:EventTypes.active];
}

+ (void)logEventAppInactive
{
    [self logEventWithType:EventTypes.inactive];
}

+ (void)logEventForeground
{
    [self logEventWithType:EventTypes.foregrounded];
}

+ (void)logEventBackground
{
    [self logEventWithType:EventTypes.backgrounded];
}

+ (void)logEventRegistered
{
    [self logEventWithType:EventTypes.registered];
}

+ (void)logEventPushReceivedWithData:(NSDictionary *)eventData
{
    [self logEventWithType:EventTypes.received eventData:eventData];
}

#pragma mark - PCFSortDescriptors Protocol

+ (NSArray *)defaultSortDescriptors
{
    return @[[NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(eventTime)) ascending:NO]];
}

#pragma mark - PCFPushMapping Protocol

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

@end
