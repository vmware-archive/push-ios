//
//  MSSPushErrorUtil.m
//  MSSPush
//
//  Created by Rob Szumlakowski on 2014-01-28.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "MSSPushErrorUtil.h"
#import "MSSPushErrors.h"

@implementation MSSPushErrorUtil

+ (NSError *)errorWithCode:(NSInteger)code localizedDescription:(NSString *)localizedDescription
{
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey:NSLocalizedString(localizedDescription, nil)};
    return [NSError errorWithDomain:MSSPushErrorDomain code:code userInfo:userInfo];
}

@end
