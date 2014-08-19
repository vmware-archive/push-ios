//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "MSSPushRegistrationPutRequestData.h"
#import "MSSPushRegistrationPostRequestData.h"

@implementation MSSPushRegistrationPutRequestData

+ (NSDictionary *)localToRemoteMapping
{
    static NSDictionary *localToRemoteMapping;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableDictionary *mapping = [NSMutableDictionary dictionaryWithDictionary:[super localToRemoteMapping]];
        mapping[MSS_STR_PROP(subscribeTags)] = [NSString stringWithFormat:@"%@.%@", kTags, kSubscribeTags];
        mapping[MSS_STR_PROP(unsubscribeTags)] = [NSString stringWithFormat:@"%@.%@", kTags, kUnsubscribeTags];
        localToRemoteMapping = [NSDictionary dictionaryWithDictionary:mapping];
    });
    
    return localToRemoteMapping;
}

@end
