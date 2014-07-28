//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "MSSBase+Analytics.h"
#import "MSSPersistentStorage+Analytics.h"

@implementation MSSBase (Analytics)

+ (BOOL)analyticsEnabled
{
    return [MSSPersistentStorage analyticsEnabled];
}

+ (void)setAnalyticsEnabled:(BOOL)enabled
{
    [MSSPersistentStorage setAnalyticsEnabled:enabled];
}

@end
