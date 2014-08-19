//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "MSSPushRegistrationPostRequestData.h"
#import "NSObject+MSSJSONizable.h"

@implementation MSSPushRegistrationPostRequestData

+ (NSDictionary *)localToRemoteMapping
{
    static NSDictionary *localToRemoteMapping;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableDictionary *mapping = [NSMutableDictionary dictionaryWithDictionary:[super localToRemoteMapping]];
        mapping[MSS_STR_PROP(tags)] = kTags;
        localToRemoteMapping = [NSDictionary dictionaryWithDictionary:mapping];
    });
    
    return localToRemoteMapping;
}

@end
