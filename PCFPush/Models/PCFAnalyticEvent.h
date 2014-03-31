//
//  PCFAnalyticEvent.h
//  
//
//  Created by DX123-XL on 2014-03-28.
//
//

#import <CoreData/CoreData.h>
#import "PCFPushMapping.h"

const struct EventAttributes {
    PCF_STRUCT_STRING *eventID;
    PCF_STRUCT_STRING *eventType;
    PCF_STRUCT_STRING *eventTime;
} EventAttributes;

@interface PCFAnalyticEvent : NSManagedObject <PCFPushMapping>

@property (nonatomic, readonly) NSString *eventType;
@property (nonatomic, readonly) NSString *eventID;
@property (nonatomic, readonly) NSString *eventTime;

+ (void)addEventWithType:(NSString *)eventType;

@end
