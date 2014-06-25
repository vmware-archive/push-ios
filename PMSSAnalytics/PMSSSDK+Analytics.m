//
//  PMSSSDK+Analytics.m
//  
//
//  Created by DX123-XL on 2014-04-25.
//
//

#import "PMSSSDK+Analytics.h"
#import "PMSSPersistentStorage+Analytics.h"

@implementation PMSSSDK (Analytics)

+ (BOOL)analyticsEnabled
{
    return [PMSSPersistentStorage analyticsEnabled];
}

+ (void)setAnalyticsEnabled:(BOOL)enabled
{
    [PMSSPersistentStorage setAnalyticsEnabled:enabled];
}

@end
