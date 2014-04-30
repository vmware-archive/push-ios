//
//  PCFParameters.m
//  PCFPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-21.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import <objc/runtime.h>

#import "PCFParameters.h"
#import "PCFPushDebug.h"

#ifdef DEBUG
static BOOL kInDebug = YES;
#else
static BOOL kInDebug = NO;
#endif


@implementation PCFParameters

+ (PCFParameters *)defaultParameters
{
    return [self parametersWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"PCFParameters" ofType:@"plist"]];
}

+ (PCFParameters *)parametersWithContentsOfFile:(NSString *)path
{
    PCFParameters *params = [PCFParameters parameters];
    if (path) {
        @try {
            NSDictionary *plistDictionary = [[NSDictionary alloc] initWithContentsOfFile:path];
            [params setValuesForKeysWithDictionary:plistDictionary];
        } @catch (NSException *exception) {
            PCFPushLog(@"Exception while populating PCFParameters object. %@", exception);
            params = nil;
        }
    }
    return params;
}

+ (PCFParameters *)parameters
{
    PCFParameters *params = [[self alloc] init];
    params.pushAutoRegistrationEnabled = YES;
    return params;
}

- (NSString *)variantUUID
{
    return kInDebug ? self.developmentPushVariantUUID : self.productionPushVariantUUID;
}

- (NSString *)releaseSecret
{
    return kInDebug ? self.developmentPushReleaseSecret : self.productionPushReleaseSecret;
}

- (NSString *)analyticsKey
{
    return kInDebug ? self.developmentPushReleaseSecret : self.productionPushReleaseSecret;
}

- (BOOL)pushParametersValid;
{
    SEL selectors[] = {
        @selector(pushDeviceAlias),
        @selector(pushAPIURL),
        @selector(pushAutoRegistrationEnabled),
        @selector(developmentPushVariantUUID),
        @selector(developmentPushReleaseSecret),
        @selector(productionPushVariantUUID),
        @selector(productionPushReleaseSecret),
    };

    for (NSUInteger i = 0; i < sizeof(selectors)/sizeof(selectors[0]); i++) {
        id value = [self valueForKey:NSStringFromSelector(selectors[i])];
        if (!value || ([value respondsToSelector:@selector(length)] && [value length] <= 0)) {
            PCFPushLog(@"PCFParameters failed validation caused by an invalid parameter %@.", NSStringFromSelector(selectors[i]));
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
            PCFPushLog(@"PCFParameters failed validation caused by an invalid parameter %@.", NSStringFromSelector(selectors[i]));
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
