//
//  MSSSDK+Analytics.m
//  
//
//  Created by DX123-XL on 2014-04-25.
//
//

#import "MSSSDK+Analytics.h"
#import "MSSPersistentStorage+Analytics.h"

@implementation MSSSDK (Analytics)

+ (BOOL)analyticsEnabled
{
    return [MSSPersistentStorage analyticsEnabled];
}

+ (void)setAnalyticsEnabled:(BOOL)enabled
{
    [MSSPersistentStorage setAnalyticsEnabled:enabled];
}

@end
