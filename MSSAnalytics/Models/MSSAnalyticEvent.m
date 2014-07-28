//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "MSSAnalyticEvent.h"
#import "MSSPushDebug.h"
#import "MSSCoreDataManager.h"
#import "MSSPersistentStorage+Analytics.h"
#import "MSSMapping.h"

const struct EventRemoteAttributes {
    MSS_STRUCT_STRING *eventID;
    MSS_STRUCT_STRING *eventType;
    MSS_STRUCT_STRING *eventTime;
    MSS_STRUCT_STRING *eventData;
} EventRemoteAttributes;

const struct EventRemoteAttributes EventRemoteAttributes = {
    .eventID      = @"id",
    .eventType    = @"type",
    .eventTime    = @"time",
    .eventData    = @"data",
};

@implementation MSSAnalyticEvent

@dynamic eventID;
@dynamic eventType;
@dynamic eventTime;
@dynamic eventData;

#pragma mark - MSSSortDescriptors Protocol

+ (NSArray *)defaultSortDescriptors
{
    return @[[NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(eventTime)) ascending:NO]];
}

#pragma mark - MSSMapping Protocol

+ (NSDictionary *)localToRemoteMapping
{
    static NSDictionary *localToRemoteMapping;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        localToRemoteMapping = @{
                                 MSS_STR_PROP(eventID)     : EventRemoteAttributes.eventID,
                                 MSS_STR_PROP(eventType)   : EventRemoteAttributes.eventType,
                                 MSS_STR_PROP(eventTime)   : EventRemoteAttributes.eventTime,
                                 MSS_STR_PROP(eventData)   : EventRemoteAttributes.eventData,
                                 };
    });
    
    return localToRemoteMapping;
}

@end
