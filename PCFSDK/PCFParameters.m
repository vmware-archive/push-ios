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
static BOOL kInProduction = NO;
#else
static BOOL kInProduction = YES;
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
    
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList([self class], &outCount);
    
    for (i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        const char *propName = property_getName(property);
        
        if (propName) {
            NSString *propertyName = [NSString stringWithCString:propName encoding:[NSString defaultCStringEncoding]];
            id value = [self valueForKey:propertyName];
            
            if (!value || ([value respondsToSelector:@selector(length)] && [value length] <= 0)) {
                valid = NO;
                PCFPushLog(@"PCFParameters failed validation caused by an invalid parameter %@.", propertyName);
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
