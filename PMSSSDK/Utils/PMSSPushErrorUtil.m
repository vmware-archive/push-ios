//
//  PMSSPushErrorUtil.m
//  PMSSPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-28.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "PMSSPushErrorUtil.h"
#import "PMSSPushErrors.h"

@implementation PMSSPushErrorUtil

+ (NSError *)errorWithCode:(NSInteger)code localizedDescription:(NSString *)localizedDescription
{
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey:NSLocalizedString(localizedDescription, nil)};
    return [NSError errorWithDomain:PMSSPushErrorDomain code:code userInfo:userInfo];
}

@end
