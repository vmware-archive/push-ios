//
//  PCFPushErrorUtil.m
//  PCFPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-28.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "PCFPushErrorUtil.h"
#import "PCFPushErrors.h"

@implementation PCFPushErrorUtil

+ (NSError *)errorWithCode:(NSInteger)code localizedDescription:(NSString *)localizedDescription
{
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey:NSLocalizedString(localizedDescription, nil)};
    return [NSError errorWithDomain:PCFPushErrorDomain code:code userInfo:userInfo];
}

@end
