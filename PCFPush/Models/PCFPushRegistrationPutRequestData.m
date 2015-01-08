//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "PCFPushRegistrationPutRequestData.h"
#import "PCFPushRegistrationPostRequestData.h"

@implementation PCFPushRegistrationPutRequestData

+ (NSDictionary *)localToRemoteMapping
{
    static NSDictionary *localToRemoteMapping;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableDictionary *mapping = [NSMutableDictionary dictionaryWithDictionary:[super localToRemoteMapping]];
        mapping[PCF_STR_PROP(subscribeTags)] = [NSString stringWithFormat:@"%@.%@", kTags, kSubscribeTags];
        mapping[PCF_STR_PROP(unsubscribeTags)] = [NSString stringWithFormat:@"%@.%@", kTags, kUnsubscribeTags];
        localToRemoteMapping = [NSDictionary dictionaryWithDictionary:mapping];
    });
    
    return localToRemoteMapping;
}

@end
