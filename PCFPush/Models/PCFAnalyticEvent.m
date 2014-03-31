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

@interface PCFAnalyticEvent ()

@property (nonatomic, readwrite) NSString *eventType;
@property (nonatomic, readwrite) NSString *eventID;
@property (nonatomic, readwrite) NSString *eventTime;

@end

@implementation PCFAnalyticEvent

@dynamic eventID;
@dynamic eventType;
@dynamic eventTime;

const struct EventAttributes EventAttributes = {
    .eventID    = @"event_id",
    .eventType  = @"event_type",
    .eventTime  = @"event_time",
};

+ (NSDictionary *)localToRemoteMapping
{
    static NSDictionary *localToRemoteMapping;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        localToRemoteMapping = @{
                                 PCF_STR_PROP(eventID) : EventAttributes.eventID,
                                 PCF_STR_PROP(eventType) : EventAttributes.eventType,
                                 PCF_STR_PROP(eventTime) : EventAttributes.eventTime,
                                 };
    });
    
    return localToRemoteMapping;
}


+ (void)addEventWithType:(NSString *)eventType
{
    NSManagedObjectContext *context = [[PCFPushCoreDataManager shared] managedObjectContext];
    [context performBlock:^{
        NSEntityDescription *description = [NSEntityDescription entityForName:NSStringFromClass(self.class) inManagedObjectContext:context];
        PCFAnalyticEvent *event = [[self alloc] initWithEntity:self insertIntoManagedObjectContext:description];
        [event setEventID:[[NSUUID UUID] UUIDString]];
        [event setEventType:eventType];
        [event setEventType:[NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970]]];
        
        NSError *error;
        if (![context save:&error]) {
            PCFPushCriticalLog(@"Managed Object Context failed to save: %@ %@", error, error.userInfo);
        }
    }];
}

@end
