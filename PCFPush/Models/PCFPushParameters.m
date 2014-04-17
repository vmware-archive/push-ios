//
//  PCFPushRegistrationParameters.m
//  PCFPushSDK
//
//  Created by Rob Szumlakowski on 2014-01-21.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import <objc/runtime.h>

#import "PCFPushParameters.h"
#import "PCFPushDebug.h"

#ifdef DEBUG
static BOOL kInProduction = NO;
#else
static BOOL kInProduction = YES;
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
    PCFPushParameters *params = [[self alloc] init];
    params.autoRegistrationEnabled = YES;
    return params;
}

- (NSString *)variantUUID
{
    return kInProduction ? self.productionVariantUUID : self.developmentVariantUUID;
}

- (NSString *)releaseSecret
{
    return kInProduction ? self.productionReleaseSecret : self.developmentReleaseSecret;
}

- (BOOL)isValid
{
    BOOL valid = YES;
    
    NSUInteger outCount, i;
    objc_property_t *properties = class_copyPropertyList([self class], &outCount);
    
    for (i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        const char *propName = property_getName(property);
        
        if (propName) {
            NSString *propertyName = [NSString stringWithCString:propName encoding:[NSString defaultCStringEncoding]];
            id value = [self valueForKey:propertyName];
            
            if (!value || ([value respondsToSelector:@selector(length)] && [value length] <= 0)) {
                valid = NO;
                PCFPushLog(@"PCFPushParameters failed validation caused by an invalid parameter %@.", propertyName);
                break;
            }
        }
    }
    free(properties);
    
    return valid;
}

- (BOOL)inProduction
{
    return kInProduction;
}

@end
