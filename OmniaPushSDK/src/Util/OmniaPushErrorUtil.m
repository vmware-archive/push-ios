//
//  OmniaPushErrorUtil.m
//  OmniaPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-28.
//  Copyright (c) 2014 Omnia. All rights reserved.
//

#import "OmniaPushErrorUtil.h"
#import "OmniaPushErrors.h"

@implementation OmniaPushErrorUtil

+ (NSError*) errorWithCode:(NSInteger)code localizedDescription:(NSString*)localizedDescription
{
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey:NSLocalizedString(localizedDescription, nil)};
    return [NSError errorWithDomain:OmniaPushErrorDomain code:code userInfo:userInfo];
}

@end
