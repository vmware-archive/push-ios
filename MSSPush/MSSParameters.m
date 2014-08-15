//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <objc/runtime.h>

#import "MSSParameters.h"
#import "MSSPushDebug.h"

#ifdef DEBUG
static BOOL kInDebug = YES;
#else
static BOOL kInDebug = NO;
#endif


@implementation MSSParameters

+ (MSSParameters *)defaultParameters
{
    return [self parametersWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"MSSParameters" ofType:@"plist"]];
}

+ (MSSParameters *)parametersWithContentsOfFile:(NSString *)path
{
    MSSParameters *params = [MSSParameters parameters];
    if (path) {
        @try {
            NSDictionary *plistDictionary = [[NSDictionary alloc] initWithContentsOfFile:path];
            [params setValuesForKeysWithDictionary:plistDictionary];
        } @catch (NSException *exception) {
            MSSPushLog(@"Exception while populating MSSParameters object. %@", exception);
            params = nil;
        }
    }
    return params;
}

+ (MSSParameters *)parameters
{
    MSSParameters *params = [[self alloc] init];
    params.pushAutoRegistrationEnabled = YES;
    return params;
}

- (NSString *)variantUUID
{
    return kInDebug ? self.developmentPushVariantUUID : self.productionPushVariantUUID;
}

- (NSString *)variantSecret
{
    return kInDebug ? self.developmentPushVariantSecret : self.productionPushVariantSecret;
}

- (NSString *)analyticsKey
{
    return kInDebug ? self.developmentAnalyticsKey : self.productionAnalyticsKey;
}

- (BOOL)pushParametersValid;
{
    SEL selectors[] = {
        @selector(pushDeviceAlias),
        @selector(pushAPIURL),
        @selector(pushAutoRegistrationEnabled),
        @selector(developmentPushVariantUUID),
        @selector(developmentPushVariantSecret),
        @selector(productionPushVariantUUID),
        @selector(productionPushVariantSecret),
    };

    for (NSUInteger i = 0; i < sizeof(selectors)/sizeof(selectors[0]); i++) {
        id value = [self valueForKey:NSStringFromSelector(selectors[i])];
        if (!value || ([value respondsToSelector:@selector(length)] && [value length] <= 0)) {
            MSSPushLog(@"MSSParameters failed validation caused by an invalid parameter %@.", NSStringFromSelector(selectors[i]));
            return NO;
            break;
        }
    }
    return YES;
}

- (BOOL)analyticsParametersValid
{
    SEL selectors[] = {
        @selector(analyticsAPIURL),
        @selector(developmentAnalyticsKey),
        @selector(productionAnalyticsKey),
    };

    for (NSUInteger i = 0; i < sizeof(selectors)/sizeof(selectors[0]); i++) {
        id value = [self valueForKey:NSStringFromSelector(selectors[i])];
        if (!value || ([value respondsToSelector:@selector(length)] && [value length] <= 0)) {
            MSSPushLog(@"MSSParameters failed validation caused by an invalid parameter %@.", NSStringFromSelector(selectors[i]));
            return NO;
            break;
        }
    }
    return YES;
}

- (BOOL)inDebugMode
{
    return kInDebug;
}

@end
