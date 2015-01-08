//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
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
