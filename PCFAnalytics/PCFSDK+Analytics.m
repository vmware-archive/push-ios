//
//  PCFSDK+Analytics.m
//  
//
//  Created by DX123-XL on 2014-04-25.
//
//

#import "PCFSDK+Analytics.h"
#import "PCFPersistentStorage+Analytics.h"

@implementation PCFSDK (Analytics)

+ (BOOL)analyticsEnabled
{
    return [PCFPersistentStorage analyticsEnabled];
}

+ (void)setAnalyticsEnabled:(BOOL)enabled
{
    [PCFPersistentStorage setAnalyticsEnabled:enabled];
}

@end
