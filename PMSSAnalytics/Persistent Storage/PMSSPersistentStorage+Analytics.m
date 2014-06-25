//
//  PMSSPersistentStorage+Analytics.m
//  
//
//  Created by DX123-XL on 2014-04-25.
//
//

#import "PMSSPersistentStorage+Analytics.h"

static NSString *const KEY_ANALYTICS_ENABLED  = @"PMSS_KEY_ANALYTICS_ENABLED";

@implementation PMSSPersistentStorage (Analytics)

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
