//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import "MSSPersistentStorage+Analytics.h"

static NSString *const KEY_ANALYTICS_ENABLED  = @"MSS_KEY_ANALYTICS_ENABLED";

@implementation MSSPersistentStorage (Analytics)

+ (void)setAnalyticsEnabled:(BOOL)enabled
{
    [self persistValue:[NSNumber numberWithBool:enabled] forKey:KEY_ANALYTICS_ENABLED];
}

+ (BOOL)analyticsEnabled
{
    NSNumber *enabled = [self persistedValueForKey:KEY_ANALYTICS_ENABLED];
    if (!enabled) {
        BOOL defaultValue = NO;
        [self setAnalyticsEnabled:defaultValue];
        return defaultValue;
    }
    return [enabled boolValue];
}

@end
