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
#import "PCFPersistentStorage+Analytics.h"
#import "PCFMapping.h"

const struct EventRemoteAttributes {
    PCF_STRUCT_STRING *eventID;
    PCF_STRUCT_STRING *eventType;
    PCF_STRUCT_STRING *eventTime;
    PCF_STRUCT_STRING *eventData;
} EventRemoteAttributes;

const struct EventRemoteAttributes EventRemoteAttributes = {
    .eventID      = @"id",
    .eventType    = @"type",
    .eventTime    = @"time",
    .eventData    = @"data",
};

@implementation PCFAnalyticEvent

@dynamic eventID;
@dynamic eventType;
@dynamic eventTime;
@dynamic eventData;

#pragma mark - PCFSortDescriptors Protocol

+ (NSArray *)defaultSortDescriptors
{
    return @[[NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(eventTime)) ascending:NO]];
}

#pragma mark - PCFMapping Protocol

+ (NSDictionary *)localToRemoteMapping
{
    static NSDictionary *localToRemoteMapping;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        localToRemoteMapping = @{
                                 PCF_STR_PROP(eventID)     : EventRemoteAttributes.eventID,
                                 PCF_STR_PROP(eventType)   : EventRemoteAttributes.eventType,
                                 PCF_STR_PROP(eventTime)   : EventRemoteAttributes.eventTime,
                                 PCF_STR_PROP(eventData)   : EventRemoteAttributes.eventData,
                                 };
    });
    
    return localToRemoteMapping;
}

@end
