//
//  PCFAnalyticEvent_TestingHeader.h
//  PCFPushSpec
//
//  Created by DX123-XL on 2014-04-03.
//
//

#import "PCFAnalyticEvent.h"

const struct EventTypes {
    PCF_STRUCT_STRING *initialized;
    PCF_STRUCT_STRING *active;
    PCF_STRUCT_STRING *inactive;
    PCF_STRUCT_STRING *foregrounded;
    PCF_STRUCT_STRING *backgrounded;
    PCF_STRUCT_STRING *registered;
    PCF_STRUCT_STRING *pushReceived;
} EventTypes;

const struct EventRemoteAttributes {
    PCF_STRUCT_STRING *eventID;
    PCF_STRUCT_STRING *eventType;
    PCF_STRUCT_STRING *eventTime;
    PCF_STRUCT_STRING *eventData;
} EventRemoteAttributes;

@interface PCFAnalyticEvent ()

+ (void)logEventWithType:(NSString *)eventType eventData:(NSDictionary *)eventData;

+ (void)insertIntoContext:(NSManagedObjectContext *)context
            eventWithType:(NSString *)eventType
                     data:(NSDictionary *)eventData;


@end
