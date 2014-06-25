//
//  PMSSAnalyticEvent.m
//  
//
//  Created by DX123-XL on 2014-03-28.
//
//

#import "PMSSAnalyticEvent.h"
#import "PMSSPushDebug.h"
#import "PMSSCoreDataManager.h"
#import "PMSSPersistentStorage+Analytics.h"
#import "PMSSMapping.h"

const struct EventRemoteAttributes {
    PMSS_STRUCT_STRING *eventID;
    PMSS_STRUCT_STRING *eventType;
    PMSS_STRUCT_STRING *eventTime;
    PMSS_STRUCT_STRING *eventData;
} EventRemoteAttributes;

const struct EventRemoteAttributes EventRemoteAttributes = {
    .eventID      = @"id",
    .eventType    = @"type",
    .eventTime    = @"time",
    .eventData    = @"data",
};

@implementation PMSSAnalyticEvent

@dynamic eventID;
@dynamic eventType;
@dynamic eventTime;
@dynamic eventData;

#pragma mark - PMSSSortDescriptors Protocol

+ (NSArray *)defaultSortDescriptors
{
    return @[[NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(eventTime)) ascending:NO]];
}

#pragma mark - PMSSMapping Protocol

+ (NSDictionary *)localToRemoteMapping
{
    static NSDictionary *localToRemoteMapping;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        localToRemoteMapping = @{
                                 PMSS_STR_PROP(eventID)     : EventRemoteAttributes.eventID,
                                 PMSS_STR_PROP(eventType)   : EventRemoteAttributes.eventType,
                                 PMSS_STR_PROP(eventTime)   : EventRemoteAttributes.eventTime,
                                 PMSS_STR_PROP(eventData)   : EventRemoteAttributes.eventData,
                                 };
    });
    
    return localToRemoteMapping;
}

@end
