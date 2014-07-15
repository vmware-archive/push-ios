//
//  MSSBase+Analytics.m
//  
//
//  Created by DX123-XL on 2014-04-25.
//
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
