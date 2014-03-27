//
//  CFPushErrorUtil.m
//  CFPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-28.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "CFPushErrorUtil.h"
#import "CFPushErrors.h"

@implementation CFPushErrorUtil

+ (NSError *)errorWithCode:(NSInteger)code localizedDescription:(NSString *)localizedDescription
{
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey:NSLocalizedString(localizedDescription, nil)};
    return [NSError errorWithDomain:CFPushErrorDomain code:code userInfo:userInfo];
}

@end
