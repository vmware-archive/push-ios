//
//  Copyright (C) 2014 Pivotal Software, Inc. All rights reserved.
//

#import <objc/runtime.h>

#import "PCFParameters.h"
#import "PCFPushDebug.h"
#import "PCFPushPersistentStorage.h"

#ifdef DEBUG
static BOOL kInDebug = YES;
#else
static BOOL kInDebug = NO;
#endif

@implementation PCFParameters

+ (PCFParameters *)defaultParameters
{
    PCFParameters *parameters = [self parametersWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[PCFParameters defaultParameterFilename] ofType:@"plist"]];
    parameters.pushTags = [PCFPushPersistentStorage tags];
    parameters.pushDeviceAlias = [PCFPushPersistentStorage deviceAlias];
    return parameters;
}

+ (NSString*) defaultParameterFilename
{
    return @"Pivotal";
}

+ (PCFParameters *)parametersWithContentsOfFile:(NSString *)path
{
    PCFParameters *params = [PCFParameters parameters];
    if (path) {
        @try {
            NSDictionary *plist = [[NSDictionary alloc] initWithContentsOfFile:path];
            [PCFParameters enumerateParametersWithBlock:^(id plistPropertyName, id propertyName, BOOL *stop) {
                id propertyValue = [plist valueForKey:plistPropertyName];
                if (propertyValue) {
                    [params setValue:propertyValue forKeyPath:propertyName];
                }
            }];
        } @catch (NSException *exception) {
            PCFPushLog(@"Exception while populating PCFParameters object. %@", exception);
            params = nil;
        }
    }
    return params;
}

+ (PCFParameters *)parameters
{
    return [[self alloc] init];
}

- (NSString *)variantUUID
{
    return kInDebug ? self.developmentPushVariantUUID : self.productionPushVariantUUID;
}

- (NSString *)variantSecret
{
    return kInDebug ? self.developmentPushVariantSecret : self.productionPushVariantSecret;
}


- (BOOL)arePushParametersValid;
{
    __block BOOL result = YES;

    [PCFParameters enumerateParametersWithBlock:^(id plistPropertyName, id propertyName, BOOL *stop) {
        id propertyValue = [self valueForKeyPath:propertyName];
        if (!propertyValue || ([propertyValue respondsToSelector:@selector(length)] && [propertyValue length] <= 0)) {
            PCFPushLog(@"PCFParameters failed validation caused by an invalid parameter %@.", propertyName);
            result = NO;
            *stop = YES;
        }
    }];
    return result;
}

+ (void) enumerateParametersWithBlock:(void (^)(id plistPropertyName, id propertyName, BOOL *stop))block
{
    static NSDictionary *keys = nil;
    if (!keys) {
        keys = @{
                @"pivotal.push.serviceUrl" : @"pushAPIURL",
                @"pivotal.push.variantUuid.production" : @"productionPushVariantUUID",
                @"pivotal.push.variantSecret.production" : @"productionPushVariantSecret",
                @"pivotal.push.variantUuid.development" : @"developmentPushVariantUUID",
                @"pivotal.push.variantSecret.development" : @"developmentPushVariantSecret",
        };
    }
    if (block) {
        [keys enumerateKeysAndObjectsUsingBlock:^(id plistPropertyName, id propertyName, BOOL *stop) {
            block(plistPropertyName, propertyName, stop);
        }];
    }
}
@end
