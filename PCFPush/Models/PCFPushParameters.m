//
//  PCFPushRegistrationParameters.m
//  PCFPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-21.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "PCFPushParameters.h"
#import "PCFPushDebug.h"

#ifdef DEBUG
static BOOL inProduction = NO;
#else
static BOOL inProduction = YES;
#endif

@implementation PCFPushParameters

+ (PCFPushParameters *)defaultParameters
{
    return [self parametersWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"PCFPushParameters" ofType:@"plist"]];
}

+ (PCFPushParameters *)parametersWithContentsOfFile:(NSString *)path
{
    PCFPushParameters *params = [PCFPushParameters parameters];
    if (path) {
        NSDictionary *paramsDictionary = [[NSDictionary alloc] initWithContentsOfFile:path];
        [params setValuesForKeysWithDictionary:paramsDictionary];
    }
    return params;
}

+ (PCFPushParameters *)parameters
{
    return [[self alloc] init];
}

- (NSString *)variantUUID
{
    return inProduction ? self.productionVariantUUID : self.developmentVariantUUID;
}

- (NSString *)releaseSecret
{
    return inProduction ? self.productionReleaseSecret : self.developmentReleaseSecret;
}

- (BOOL)validate
{
    BOOL valid = YES;
    if (!self.variantUUID || self.variantUUID.length <= 0) {
        valid = NO;
        PCFPushError(@"PCFPushParameters failed validation caused by an invalid variantUUID.");
    }
    if (!self.releaseSecret || self.releaseSecret.length <= 0) {
        valid = NO;
        PCFPushError(@"PCFPushParameters failed validation caused by an invalid releaseSecret.");
    }
    if (!self.deviceAlias) {
        valid = NO;
        PCFPushError(@"PCFPushParameters failed validation caused by an invalid deviceAlias.");
    }
    
    return valid;
}

@end
